# Installed by `setup_brew` (zsh/functions/setup.zsh) via `brew bundle`. Native Homebrew only (/opt/homebrew).
# Preview what is missing: brew bundle check --file=Brewfile --verbose
# A comment starting with "TUI:" marks a program with its own full-screen keys: docs/vim-keys.md, "Config",
# says how it gets vim keys (a check, checks/consistency.zsh, holds it to that).

# This Mac's kind, home or work (setup_machine asks once). Every Mac gets all packages below; one that only
# one kind needs goes in a block like `if kind == "work"` … `end`
kind = File.read(File.expand_path("~/.config/dotfiles/kind")).strip rescue ""

tap "nikitabobko/tap"              # aerospace

# --- Used by these dotfiles
brew "git"                         # newer than Apple's, config/git/.gitconfig
brew "uv"                          # python versions, venvs, tools; setup_python, mds
brew "zsh"                         # the login shell, prepare-zsh-install.sh
brew "zsh-completions"             # extra completions, zsh/.zshdefault
brew "fzf-tab"                     # zsh plugins, sourced in zsh/.zshdefault
brew "zsh-autosuggestions"         # zsh plugin, zsh/.zshdefault
brew "zsh-fast-syntax-highlighting" # zsh plugin, zsh/.zshdefault
brew "atuin"                       # TUI: C-r history search, config/atuin
brew "starship"                    # prompt, config/starship.toml
brew "fnm"                         # node versions, zsh/.exports
brew "vivid"                       # LS_COLORS for eza / completion, zsh/.exports
brew "tmux"                        # config/tmux, setup_tmux
brew "terminal-notifier"           # Claude Code notifications you can click, config/claude/hooks/notify.sh
brew "vhs"                         # records the GIFs in docs/ from docs/tapes, make_gifs
brew "git-delta"                   # git pager (config/git/.gitconfig)
brew "difftastic"                  # git dft / dlog / dshow
brew "gh"                          # GitHub CLI
brew "fzf"                         # setup_fzf
brew "eza"                         # replaces the discontinued exa
brew "zoxide"                      # z / zi, zsh/.zshdefault
brew "bat"                         # file previews in fzf, .fzf.zsh
brew "lesspipe"                    # zsh/.exports
brew "fd"                          # file lists for fzf (.fzf.zsh), mdv
brew "glow"                        # TUI: mdv, zsh/functions/fzf.zsh: renders markdown in the terminal
brew "ripgrep"                     # rg: fzf-lua grep and grug-far in nvim, fif and ;r in .fzf.zsh
brew "neovim"                      # setup_nvim, config/nvim
brew "lua-language-server"         # Lua language server in nvim, lsp/lspconfig/lua_ls.lua
brew "typescript-language-server"  # TypeScript/JavaScript language server in nvim, lsp/lspconfig/ts_ls.lua
brew "vscode-langservers-extracted" # ESLint language server in nvim, lsp/lspconfig/eslint.lua
brew "yaml-language-server"        # YAML language server in nvim, lsp/lspconfig/yamlls.lua
brew "gopls"                       # Go language server in nvim, lsp/lspconfig/gopls.lua
brew "tree-sitter"                 # parser library for nvim treesitter
brew "tree-sitter-cli"             # compiles the nvim treesitter parsers
brew "lazygit"                     # TUI: `lg` alias, `,lg` in nvim (config/lazygit/nvim.yml)
brew "podman"                      # containers, `docker` (~/bin/docker): setup_podman, docs/podman.md
brew "docker-compose"              # `docker compose` on podman (docs/podman.md)
brew "awscli"                      # aws (docs/aws.md), profiles in ~/.aws/config; brings its own zsh completion
brew "kubernetes-cli"              # `k` aliases in zsh/.aliases
brew "hyperfine"                   # benchmarks, `timezsh`
brew "shfmt"                       # formats shell scripts: conform in nvim, the Claude format hook
brew "pam-reattach"                # Touch ID for sudo inside tmux, setup_touch_id_sudo

# --- Everyday tools: for you at the prompt; nothing in the repo needs one unless its comment names the user
brew "wget"                        # downloads
brew "gnu-sed"                     # gsed, GNU sed for scripts written for Linux
brew "jq"                          # JSON in scripts: Claude Code hooks, status line, mds
brew "yq"                          # jq for YAML (and TOML, XML)
brew "shellcheck"                  # finds bugs in shell scripts
brew "ast-grep"                    # search and rewrite code by syntax, not text
brew "just"                        # project task runner: `just <recipe>` from a justfile
brew "xh"                          # HTTP requests, httpie-compatible syntax
brew "argocd"                      # Argo CD from the command line: deploys, health, sync (docs/argocd.md)
brew "btop"                        # TUI: processes, CPU, memory, network; config/btop, setup_btop
brew "yazi"                        # TUI: file manager with previews; ,e in zsh's normal mode (.fzf.zsh)
brew "chafa"                       # images and GIFs in the terminal, `img`
brew "tlrc"                        # `tldr <cmd>`: short examples
brew "dust"                        # what takes the disk space
brew "exiftool"                    # reads and strips image metadata
brew "imagemagick"                 # converts and resizes images (magick)
brew "graphviz"                    # dot: renders graphs to images
brew "dockutil"                    # edits the Dock from the command line
brew "go"                          # Go toolchain, for gopls and delve

# --- Debugging, docs/debugging.md
cask "visual-studio-code"          # the visual debugger for backends and the web, setup_vscode, `,vo` in nvim
brew "delve"                       # Go debugger, used by VS Code's Go extension

# --- Mobile development, docs/mobile.md (Xcode itself comes from the App Store)
brew "xcode-build-server"          # sourcekit-lsp in nvim understands Xcode projects, xcodebuild.nvim
brew "xcbeautify"                  # readable xcodebuild output in nvim, xcodebuild.nvim
brew "swiftformat"                 # formats Swift where a project has a .swiftformat, conform in nvim
cask "android-studio"              # Android SDK, emulators, layout previews, debugging; `,ao` in nvim, zsh/.exports
cask "kotlin-lsp"                  # Kotlin language server (JetBrains) in nvim, lsp/lspconfig/kotlin_lsp.lua
brew "ktlint"                      # formats Kotlin where a project's .editorconfig sets up ktlint, conform in nvim

# --- Apps
cask "ghostty"                     # the terminal, config/ghostty, setup_ghostty
cask "nikitabobko/tap/aerospace"   # tiling windows, config/aerospace, setup_window_management
cask "secretive"                   # ssh keys in the Secure Enclave, config/ssh/config, secretive_key
cask "font-source-code-pro"        # the font in Ghostty, config/ghostty/config
cask "font-symbols-only-nerd-font" # Nerd Font icons in the GIFs, make_gifs
cask "google-chrome"               # browser
cask "firefox@developer-edition"   # browser with dev tools
cask "cyberduck"                   # SFTP, S3 and cloud storage browser
cask "signal"                      # messenger
cask "spotify"                     # music; shpotify below controls it
brew "shpotify"                    # provides `spotify` for the aliases in zsh/.aliases

# --- Home-like Macs only
if kind == "home"
  cask "tunnelblick"               # personal VPN; a work Mac has the company's, and two VPN clients clash
end

# --- Work-like Macs only
if kind == "work"
  cask "gcloud-cli"                # gcloud, bq, gsutil; PATH and completion in zsh/.exports, zsh/.zshdefault
end

# --- This Mac's own packages, not in the repo (setup_machine, config/machine/Brewfile)
machine_brewfile = File.expand_path("~/.config/dotfiles/Brewfile")
instance_eval(File.read(machine_brewfile), machine_brewfile) if File.exist?(machine_brewfile)

# --- Review: installed on the old Mac, probably leftovers. Uncomment what you still use.
# cask "docker-desktop"  # podman is `docker` (docs/podman.md)
# brew "ansible"
# brew "aws-sam-cli"
# brew "minikube"
# brew "mitmproxy"
# brew "openconnect"
# brew "packer"
# brew "redis"
# brew "saml2aws"
# brew "tor"
# brew "yarn"            # pulls in Homebrew's node; fnm already provides node
# cask "vagrant"
# cask "virtualbox"      # runs x86 guests only; not useful on Apple silicon
# cask "evernote"
# cask "skype"           # discontinued by Microsoft
# cask "qownnotes"
# cask "gifcapture"
# brew "navi"            # cheatsheets on C-g; atuin, tldr and Claude Code cover it
# brew "cmake"           # built telescope-fzf-native; fzf-lua, which replaced telescope, runs fzf itself
