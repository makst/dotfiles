Argo CD
===

`argocd`, the command line for an Argo CD server: see what is deployed, whether it is healthy and in sync,
and what changed, without opening the web UI.

What it is
---
- **Argo CD** deploys to Kubernetes from git (GitOps): each *application* points at a chart or manifests in a
  repo and a target cluster and namespace, and Argo CD keeps the cluster matching git. An application is
  *Synced* when the cluster matches git and *Healthy* when its pods, rollouts and the rest are up.
- **The CLI** talks to the Argo CD server's API with your login, so it shows and allows what the web UI does;
  it doesn't need kubectl access to the clusters it deploys to.
- It comes from the `argocd` formula in the Brewfile, on every Mac; Homebrew installs its zsh completion.
  Logins live in `~/.config/argocd/config`, outside the repo.

Once per Mac
---
### Signing in

```zsh
argocd login <server> --sso --grpc-web   # opens the browser for the server's single sign-on
argocd account get-user-info             # who you are logged in as
```

`<server>` is the host of the web UI, without `https://`. `--grpc-web` is needed when the server sits behind a
proxy or ingress without HTTP/2 (most do); try without it if the login hangs or fails the other way. The
login expires after a while; run the same command again.

Several servers: each login is a *context*, named after the server; `argocd context` lists them and
`argocd context <name>` switches.

Checking a deploy
---
1. `argocd app list -l <label>` or `argocd app list | rg <service>` finds the application's name.
2. `argocd app get <app>` shows sync and health, the git revision, and each resource that isn't Healthy.
3. `argocd app history <app>` lists the revisions deployed, newest last.
4. `argocd app diff <app>` shows what differs between git and the cluster when it is OutOfSync.
5. `argocd app logs <app> --tail 100` reads the pods' logs, if your role allows it.

Commands
---
| Command | What it does |
|---|---|
| `argocd app list` | every application with its project, cluster, namespace, sync and health; `-p <project>` or `-l <label>` narrows it, `-o name` prints names only |
| `argocd app get <app>` | one application: source repo and revision, sync and health, its resources and their state |
| `argocd app get <app> --refresh` | the same after re-reading git, instead of waiting for the next poll |
| `argocd app resources <app>` | the Kubernetes resources it manages, one per line |
| `argocd app history <app>` | deploys: history ID, date, git revision |
| `argocd app diff <app>` | git against the live cluster |
| `argocd app manifests <app>` | the rendered manifests Argo CD applies |
| `argocd app logs <app>` | pod logs: `--tail N`, `-f` to follow, `-c <container>`, `--name <pod>` |
| `argocd app wait <app> --health` | blocks until the application is Healthy (`--timeout <s>`) |
| `argocd app sync <app>` | deploys what git says now, if your role allows it |
| `argocd app rollback <app> <history-id>` | deploys an earlier revision; auto-sync must be off or it syncs straight back |
| `argocd app get <app> -o json \| jq …` | any of the above as JSON or YAML (`-o json`, `-o yaml`) for scripts |
| `argocd context` | servers you are logged in to; `argocd context <name>` switches |
| `argocd account get-user-info` | the logged-in user and groups |

Config
---
| Part | Where | What it does |
|---|---|---|
| `argocd` formula | `Brewfile` | the CLI; updates with `brew upgrade` |
| Completion | `/opt/homebrew/share/zsh/site-functions/_argocd`, from the formula | `argocd <Tab>` completes commands, flags and, once logged in, application names |
| Logins | `~/.config/argocd/config` | servers, tokens and the current context; not in the repo |

To look out for
---
- `rpc error: code = Unauthenticated` or `token is expired`: the login ran out; run `argocd login` again.
- The login hangs or fails with an HTTP/2 or `unexpected EOF` error: add or drop `--grpc-web`.
- `argocd app sync` or `rollback` on an app with auto-sync: Argo CD returns it to what git says. Change git
  (revert the commit) to deploy something else for good.
- A read-only role sees every command in `--help` but gets `permission denied` on `sync`, `rollback`, `logs`
  and the like; that's the server's RBAC, not the CLI.

Decisions
---
- **On every Mac, not only work-like ones**: it is a small, general tool for any Argo CD server, and having it
  everywhere is simpler than a `kind` block.
- **No aliases**: the commands are used now and then, and completion already shortens them.
