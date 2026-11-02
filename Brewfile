# Installed by `brew_setup` (zsh/.functions) via `brew bundle`. Native Homebrew only (/opt/homebrew).
# Preview what is missing: brew bundle check --file=Brewfile --verbose

# This Mac's kind, home or work (setup_machine asks once). Every Mac gets all packages below; one that only
# one kind needs goes in a block like `if kind == "work"` … `end`
kind = File.read(File.expand_path("~/.config/dotfiles/kind")).strip rescue ""

tap "nikitabobko/tap"              # aerospace

# --- Used by these dotfiles
brew "git"
brew "wget"
brew "uv"                          # python versions, venvs, tools; setup_python
brew "zsh"
brew "zsh-completions"
brew "fzf-tab"                     # zsh plugins, sourced in zsh/.zshdefault
brew "zsh-autosuggestions"
brew "zsh-fast-syntax-highlighting"
brew "atuin"                       # C-r history search, config/atuin
brew "starship"                    # prompt, config/starship.toml
brew "fnm"                         # node versions, zsh/.exports
brew "vivid"                       # LS_COLORS for eza / completion, zsh/.exports
brew "tmux"
brew "vhs"                         # records the GIFs in docs/ from docs/tapes, make_gifs
brew "git-delta"                   # git pager (config/git/.gitconfig)
brew "difftastic"                  # git dft / dlog / dshow
brew "gh"                          # GitHub CLI
brew "gnu-sed"
brew "cmake"
brew "fzf"                         # fzf_setup
brew "eza"                         # replaces the discontinued exa
brew "zoxide"                      # z / zi, zsh/.zshdefault
brew "bat"
brew "lesspipe"                    # zsh/.exports
brew "fd"
brew "glow"                        # mdv, zsh/.functions: renders markdown in the terminal
brew "ripgrep"
brew "neovim"                      # setup_nvim, config/nvim
brew "tree-sitter"
brew "tree-sitter-cli"            # compiles the nvim treesitter parsers
brew "lazygit"                     # `lg` alias
brew "podman"                      # `docker` alias
brew "docker-compose"
brew "kubernetes-cli"              # `k` aliases in zsh/.aliases
brew "hyperfine"                   # benchmarks, `timezsh`
brew "shfmt"                       # formats shell scripts: conform in nvim, the Claude format hook
brew "pam-reattach"                # Touch ID for sudo inside tmux, setup_touch_id_sudo

# --- Everyday tools
brew "jq"
brew "yq"                          # jq for YAML (and TOML, XML)
brew "shellcheck"                  # finds bugs in shell scripts
brew "ast-grep"                    # search and rewrite code by syntax, not text
brew "xh"                          # HTTP requests, httpie-compatible syntax
brew "btop"                        # processes, CPU, memory, network
brew "yazi"                        # file manager with previews
brew "chafa"                       # images and GIFs in the terminal, `img`
brew "tlrc"                        # `tldr <cmd>`: short examples
brew "dust"                        # what takes the disk space
brew "exiftool"
brew "imagemagick"
brew "graphviz"
brew "dockutil"
brew "go"

# --- Mobile development, docs/mobile.md (Xcode itself comes from the App Store)
brew "xcode-build-server"          # sourcekit-lsp in nvim understands Xcode projects, xcodebuild.nvim
brew "xcbeautify"                  # readable xcodebuild output in nvim, xcodebuild.nvim
brew "swiftformat"                 # formats Swift where a project has a .swiftformat, conform in nvim
cask "android-studio"              # Android SDK, emulators, layout previews, debugging; `,ao` in nvim, zsh/.exports
cask "kotlin-lsp"                  # Kotlin language server (JetBrains) in nvim, lsp/lspconfig/kotlin_lsp.lua
brew "ktlint"                      # formats Kotlin where a project's .editorconfig sets up ktlint, conform in nvim

# --- Apps
cask "ghostty"
cask "nikitabobko/tap/aerospace"   # tiling windows, config/aerospace, setup_window_management
cask "secretive"                   # ssh keys in the Secure Enclave, config/ssh/config, secretive_key
cask "font-source-code-pro"
cask "font-symbols-only-nerd-font" # Nerd Font icons in the GIFs, make_gifs
cask "google-chrome"
cask "firefox@developer-edition"
cask "cyberduck"
cask "signal"
cask "spotify"
brew "shpotify"                    # provides `spotify` for the aliases in zsh/.aliases

# --- Home-like Macs only
if kind == "home"
  cask "tunnelblick"               # personal VPN; a work Mac has the company's, and two VPN clients clash
end

# --- This Mac's own packages, not in the repo (setup_machine, config/machine/Brewfile)
machine_brewfile = File.expand_path("~/.config/dotfiles/Brewfile")
instance_eval(File.read(machine_brewfile), machine_brewfile) if File.exist?(machine_brewfile)

# --- Review: installed on the old Mac, probably leftovers. Uncomment what you still use.
# cask "docker-desktop"  # `docker` is aliased to podman
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
