podman
===

Containers without Docker Desktop: `docker`, `docker compose` and anything that talks to the Docker API run
on podman.

What it is
---
- **A VM runs the containers.** macOS can't run Linux containers itself, so podman keeps a small Linux VM, the
  *machine* `podman-machine-default`, and the `podman` command on the Mac talks to it over a *connection*.
  Without a running VM, every container command fails.
- **`docker` is podman.** `~/bin/docker` is a link to podman, so scripts that look for `docker` (`command -v
  docker`, a `Makefile`, `npm run`) find it outside an interactive shell too. `docker compose` becomes `podman
  compose`, which runs Homebrew's `docker-compose` against the VM.
- **The Docker API**: the VM serves it on a socket in macOS's temp directory for you (`getconf
  DARWIN_USER_TEMP_DIR`), and `DOCKER_HOST` points there, so tools
  that speak the API themselves (`docker-compose` run directly, testcontainers) find it.
- `setup_podman` makes all of this: the link, and a VM with half the cores, a quarter of the memory (4 to 8
  GB) and a 100 GB disk that only takes what it uses. It starts the VM, but nothing starts it at login.

Once per Mac
---
`setup_podman`, which `setup_dotfiles` runs. After a restart, `podman machine start`.

Commands
---
| Command | What it does |
|---|---|
| `podman machine start` / `stop` | starts or stops the VM; stopped, it frees its memory |
| `podman machine list` | the VM: running or not, CPUs, memory, disk |
| `podman machine set --cpus 4 --memory 6144` | other sizes; the VM must be stopped |
| `podman system connection list` | the connections and the VM each points at |
| `docker …`, `docker compose …` | podman, the same commands and flags |

Config
---
| Part | Where | What it does |
|---|---|---|
| `podman`, `docker-compose` formulas | `Brewfile` | the CLI and the VM's tools; compose files through `docker compose` |
| `setup_podman` | `zsh/functions/podman.zsh` | links `~/bin/docker`, removes connections to a VM that's gone, creates the VM if missing and starts it. Skipped where the Mac has no hypervisor (GitHub's runners) |
| `~/bin/docker` | link to `/opt/homebrew/bin/podman` | `docker` for scripts, not only for the shell |
| `DOCKER_HOST` | `zsh/.exports` | the VM's API socket, for tools that talk to it directly |
| The VM | `~/.local/share/containers/podman/machine`, `~/.config/containers` | its disk and settings; not in the repo |

`check_mac` reports a missing VM and a connection to one that's gone.

To look out for
---
- `VM does not exist`, or a connection error to `localhost` on a port: the VM was removed but its connection
  wasn't. `setup_podman` removes the connection and makes a new VM.
- `Cannot connect to the Docker daemon` from `docker-compose` or testcontainers: the VM is stopped
  (`podman machine start`), or the shell was opened before `DOCKER_HOST` was set (`exec zsh`).
- Ports below 1024 and a few images need root inside the VM: `podman machine stop; podman machine set
  --rootful; podman machine start`.
- Images from a private registry: `podman login <registry>`; podman also reads `~/.docker/config.json`.

Decisions
---
- **podman, not Docker Desktop**: no licence, no app running in the background.
- **A link, not an alias, for `docker`**: an alias exists only in an interactive zsh, so scripts didn't see
  `docker` at all. The link lives in `~/bin` like `vim`, not in `/usr/local` (native arm64 only). It replaces
  the alias, so there's one `docker`.
- **podman's `docker`, not Docker's CLI on top of podman**: a second CLI would bring its own contexts, which
  can point at a VM that's gone, as podman's connections did.
- **Not started at login**: the VM holds its memory while it runs; containers are used now and then.
- **No `podman-mac-helper`**: it puts the API at `/var/run/docker.sock` but needs `sudo`; `DOCKER_HOST` does
  the same without it.
