# Google Cloud

`gcloud`, `bq` and `gsutil` on work-like Macs, set up so Claude Code can look around a Google Cloud
organisation with your login but can't change it.

## What is set up
| Part | Where | What it does |
|---|---|---|
| `gcloud-cli` cask | `Brewfile`, `kind == "work"` block | `gcloud`, `gsutil`, `bq` and a bundled Python; updates with `brew upgrade` |
| PATH | `zsh/.exports` | adds `/opt/homebrew/share/google-cloud-sdk/bin`: components that `gcloud components install` adds, such as `gke-gcloud-auth-plugin`, live there |
| Completion | `zsh/.zshdefault` | gcloud's own completion script, sourced after `compinit` when the cask is installed (~1 ms) |
| Prompt | `config/starship.toml` | the active project next to the kubernetes context, so it's clear whether a command goes to staging or production |
| Claude Code | `config/claude/settings.json` | `deny` rules for commands that change things (below) |

Config and credentials live in `~/.config/gcloud`, outside the repo.

## Signing in
Once per Mac, in a terminal (the login opens the browser):

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

## What Claude Code can do
Claude Code runs `gcloud` with your login, so it sees what you see. It reads freely (`list`, `describe`,
`logging read`, `bq show`, `bq query`) and these are denied, on every Mac (`config/claude/settings.json`):

| Denied | Why |
|---|---|
| `gcloud … create / delete / deploy / update / patch / import / enable / disable / start / stop / reset / resize / rollback / publish / execute` | changes resources |
| `gcloud … set-iam-policy / add-iam-policy-binding / remove-iam-policy-binding` | changes access |
| `gcloud config set …` | would switch the project in every terminal too; Claude passes `--project` instead |
| `gcloud storage rm / mv / cp / rsync`, `gsutil rm / mv / cp / rsync / setmeta / acl / iam` | changes buckets |
| `bq rm / mk / load / cp / update / insert / truncate` | changes datasets and tables |

The rules match words anywhere after `gcloud`, so a read whose filter contains ` delete ` is denied too; run
that one yourself with `!`. `bq query` isn't denied and could run SQL that changes data (`DELETE`,
`UPDATE`); Claude asks before anything like that like any other command. When you want Claude to make a
change, run the command it suggests yourself.

## Getting to know a project
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
