Google Cloud
===

`gcloud`, `bq` and `gsutil` on work-like Macs, set up so Claude Code can look around a Google Cloud
organisation with your login but can't change it.

What it is
---
- **The tools** come from the `gcloud-cli` cask in the Brewfile's work block and update with `brew upgrade`.
  Completion is gcloud's own; the prompt shows the active project inside git repos, so it's clear whether a
  command goes to staging or production: a project with "prod" in its name is red, with `PROD` in front.
- **Config and credentials** live in `~/.config/gcloud`, outside the repo.

### What Claude Code can do

Claude Code runs `gcloud` with your login, so it sees what you see. It reads freely (`list`, `describe`,
`logging read`, `bq show`, `bq query`) and these are denied, on every Mac (`config/claude/settings.json`):

| Denied | Why |
|---|---|
| `gcloud … create / delete / deploy / update / patch / import / enable / disable / start / stop / reset / resize / rollback / publish / execute` | changes resources |
| `gcloud … set-iam-policy / add-iam-policy-binding / remove-iam-policy-binding` | changes access |
| `gcloud config set …` | would switch the project in every terminal too; Claude passes `--project` instead |
| `gcloud storage rm / mv / cp / rsync`, `gsutil rm / mv / cp / rsync / setmeta / acl / iam` | changes buckets |
| `bq rm / mk / load / cp / update / insert / truncate` | changes datasets and tables |

When you want Claude to make a change, run the command it suggests yourself. With a [Viewer service
account](#read-only-for-real-a-viewer-service-account), Claude's shell acts as an account that only has Viewer
access, while your own terminals keep your login; the deny rules stay as a second layer.

Once per Mac
---
### Signing in

In a terminal (the login opens the browser):

```zsh
gcloud auth login --update-adc          # gcloud, bq, gsutil, and application default credentials
gcloud config set project <project-id>  # the default project; --project overrides it per command
```

`--update-adc` also writes the application default credentials that client libraries and local servers use,
so `gcloud auth application-default login` isn't needed separately. For GKE clusters, add the kubectl plugin
and fetch a cluster's credentials:

```zsh
gcloud components install gke-gcloud-auth-plugin
gcloud container clusters get-credentials <cluster> --region <region> --project <project-id>
```

Several accounts or default projects: one named configuration each (`gcloud config configurations create
<name>`, then `… activate <name>`); the prompt shows the active project.

### Read-only for real: a Viewer service account

Once per work Mac (an admin may have to run the role bindings):

```zsh
sa=claude-viewer@<project>.iam.gserviceaccount.com
gcloud iam service-accounts create claude-viewer --project <project> --display-name "Claude Code, read-only"
gcloud organizations add-iam-policy-binding <org-id> --member serviceAccount:$sa --role roles/viewer
gcloud iam service-accounts add-iam-policy-binding $sa --project <project> \
  --member user:<you> --role roles/iam.serviceAccountTokenCreator   # lets you act as it
```

Then add it to this Mac's Claude settings, `~/.config/dotfiles/claude.json`, which the `claude` wrapper merges
in ([Claude Code](claude-code.md#this-machine)):

```json
{ "env": { "CLOUDSDK_AUTH_IMPERSONATE_SERVICE_ACCOUNT": "claude-viewer@<project>.iam.gserviceaccount.com" } }
```

Without org-wide access, bind `roles/viewer` per project or folder instead. `roles/viewer` doesn't read
BigQuery table data or private logs; add `roles/bigquery.dataViewer` or `roles/logging.privateLogViewer` if
Claude should. `check_mac` reminds you on a work Mac that is signed in to gcloud without this.

Getting to know a project
---
Read-only commands that show what's there; Claude runs the same when asked to map a project.

```zsh
gcloud projects list
gcloud services list --enabled --project <p>       # which Google Cloud products the project uses
gcloud asset search-all-resources --scope=projects/<p> --format='value(assetType)' | sort | uniq -c | sort -rn
gcloud container clusters list --project <p>       # GKE
gcloud run services list --project <p>             # Cloud Run
gcloud sql instances list --project <p>            # Cloud SQL
gcloud pubsub topics list --project <p>
bq ls --project_id <p>                             # BigQuery datasets
gcloud logging read 'severity>=ERROR' --freshness=1h --limit 20 --project <p>
```

`asset search-all-resources` needs the Cloud Asset API enabled and `cloudasset.assets.searchAllResources`;
without them, the per-product lists above cover the same.

Config
---
| Part | Where | What it does |
|---|---|---|
| `gcloud-cli` cask | `Brewfile`, `kind == "work"` block | `gcloud`, `gsutil`, `bq` and a bundled Python; updates with `brew upgrade` |
| PATH | `zsh/.exports` | adds `/opt/homebrew/share/google-cloud-sdk/bin`: components that `gcloud components install` adds, such as `gke-gcloud-auth-plugin`, live there |
| Completion | `zsh/.zshdefault` | gcloud's own completion script, sourced after `compinit` when the cask is installed (~1 ms) |
| Prompt | `config/starship.toml`, `_prompt_gcloud` in `zsh/.zshdefault` | the active project inside git repos; zsh reads it from gcloud's config files before each prompt, without starting a process |
| Claude Code | `config/claude/settings.json` | `deny` rules for commands that change things ([What Claude Code can do](#what-claude-code-can-do)) |
| Claude Code, this Mac | `~/.config/dotfiles/claude.json` | the Viewer service account, as `CLOUDSDK_AUTH_IMPERSONATE_SERVICE_ACCOUNT` |

To look out for
---
- The deny rules match words anywhere after `gcloud`, so a read whose filter contains ` delete ` is denied
  too; run that one yourself with `!`.
- `bq query` isn't denied and could run SQL that changes data (`DELETE`, `UPDATE`); Claude asks before
  anything like that like any other command.
- With the service account, each command Claude runs prints
  `WARNING: This command is using service account impersonation`: that's the sign it works. A command that doesn't print it (check `bq` once) runs with your
  login, and only the deny rules hold it back.
- Application default credentials (client libraries, a local server Claude starts) still use your login.
- Claude Code started from the desktop app or an IDE skips the wrapper and so the service account: start it
  from a terminal for cloud work.

Decisions
---
- **A Viewer service account on top of the deny rules**: the deny rules are a list of words, and a list can
  miss one: `gcloud compute ssh`, a verb nobody listed, a raw API call with `curl` and your token. The
  service account makes the read-only rule hold whatever Claude types.
- **`gcloud config set` denied**: it would switch the project in every terminal; Claude passes `--project`.
