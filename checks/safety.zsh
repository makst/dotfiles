# Safety checks: nothing the repo publishes can hurt the user or a Mac that takes it: no secret (a token, a
# private key), no real email address, the private files stay out of git, config/claude (~/.claude on any
# machine, docs/claude-code.md) names nothing of this Mac or this repo, nothing reaches for Intel Homebrew or
# Rosetta, no code deletes what can't be put back, and no setup step links over a real file. Sourced by
# check_dotfiles; lib.zsh has the helpers.

# secrets: no file holds a token or a private key. Prints the kind and where, never the secret itself, so it
# doesn't land in CI's log either.
check_secrets() {
  local -A kinds=(
    'gh[pousr]_[A-Za-z0-9]{36}' 'a GitHub token'
    'github_pat_[A-Za-z0-9_]{60,}' 'a GitHub token'
    'sk-ant-[A-Za-z0-9_-]{20,}' 'an Anthropic API key'
    'sk-[A-Za-z0-9]{40,}' 'an API key'
    'AKIA[0-9A-Z]{16}' 'an AWS access key'
    'AIza[0-9A-Za-z_-]{35}' 'a Google API key'
    'xox[abprs]-[0-9A-Za-z-]{10,}' 'a Slack token'
    'glpat-[0-9A-Za-z_-]{20}' 'a GitLab token'
    '-----BEGIN ([A-Z]+ )?PRIVATE KEY-----' 'a private key'
  )
  local pattern
  for pattern in ${(k)kinds}; do
    grep -nE -e $pattern -- $text_files | awk -F: -v kind=$kinds[$pattern] '{ print $1 ":" $2 ": " kind }'
  done
  note=$(count $#kinds kind)
}

# emails: the only addresses in the repo are GitHub's noreply ones (the commits' identity), git@github.com and
# made-up ones on the names kept for examples (example.com, .example, .local, .test, .invalid), so neither a
# work nor a private address gets published
check_emails() {
  grep -noE '[A-Za-z0-9._%+-]+@[A-Za-z0-9-]+(\.[A-Za-z0-9-]+)*\.[A-Za-z]{2,}' -- $text_files |
    awk -F: '
      $3 ~ /noreply/ || $3 == "git@github.com" { next }
      $3 ~ /@(.+\.)?example\.(com|org|net)$/ || $3 ~ /\.(example|local|test|invalid)$/ { next }
      { print $1 ":" $2 ": a real email address; use an example.com one" }
    '
  note=$(count $#text_files file)
}

# private files: zsh/.private and config/nvim/lua/user/hidden/ (secrets, work settings) are ignored by git and
# none of them is tracked, so a `git add .` can't publish them
check_private() {
  local p
  for p in zsh/.private config/nvim/lua/user/hidden/x.lua; do
    git check-ignore -q --no-index -- $p || print -r -- "$p: not ignored by git"
  done
  git ls-files -- zsh/.private config/nvim/lua/user/hidden | sed 's/$/: tracked by git, but private/'
  note="zsh/.private, nvim's hidden/"
}

# config/claude is ~/.claude on every machine, next to work projects' own setups: it names no machine path
# (/opt/homebrew, a home), nothing of this repo (real_script_dir, ~/.config/dotfiles, the repo's own path) and
# no tool of this Mac beyond zsh, jq, git and gh that runs without a check (CLAUDE.md, "config/claude is global")
check_claude_global() {
  local -a claude=(${(M)text_files:#config/claude/*})
  grep -nE '/opt/homebrew|/usr/local|real_script_dir|DOTFILES|\.config/dotfiles|repos/dotfiles|/Users/|/home/' \
    -- $claude | awk -F: '{ print $1 ":" $2 ": names this Mac or this repo; config/claude is ~/.claude anywhere" }'
  note=$(count $#claude file)
}

# Apple silicon only: no code reaches for an Intel Homebrew (/usr/local), x86_64 builds or Rosetta (CLAUDE.md,
# "What this repo assumes"); prepare-zsh-install.sh, which checks for them, and the docs, which say so, may
# name them
check_arm64() {
  local -a code=(${${text_files:#*.md}:#(prepare-zsh-install.sh|checks/safety.zsh)})
  grep -nE '/usr/local|x86_64|arch -x86|[Rr]osetta' -- $code |
    awk -F: '$3 !~ /^[[:space:]]*(#|--|\/\/)/ { print $1 ":" $2 ": Intel or Rosetta; this repo is native arm64" }'
  note=$(count $#code file)
}

# deletes: no code deletes recursively (rm -r, find -delete, git clean -f): what it removes can't be put back,
# so it goes to the Trash (CLAUDE.md, "Deleting"). The rm hook names them to refuse them, its cases list them;
# checks/mutate cleans its own throwaway worktree. Comments are skipped.
check_deletes() {
  local -a code=(${${text_files:#*.md}:#(config/claude/hooks/no-recursive-rm.sh|checks/(rm-hook.cases|mutate|safety.zsh))})
  grep -nE '(^|[^A-Za-z_-])rm[[:space:]]+(-[A-Za-z]*[rR]|--recursive)|[[:space:]]-delete([[:space:]]|$)|git[[:space:]]+clean[[:space:]]+(-[A-Za-z]*f|--force)' \
    -- $code | awk -F: '$3 !~ /^[[:space:]]*(#|--|\/\/)/ { print $1 ":" $2 ": deletes for good; move it to the Trash" }'
  note=$(count $#code file)
}

group "Safety: nothing published can hurt the user or a Mac"
# links: `ln -sf` replaces a real file for good, so a setup step's link comes after keep_real, which moves
# one to the Trash (docs/design.md, "Safe to try"): on the same line, or on the line before, ending in &&.
# A link behind a test of its own ([[ … ]] || ln) is left to that test.
check_links_keep() {
  awk '
    FNR == 1 { prev = "" }
    /^[[:space:]]*ln -s/ && prev !~ /^[[:space:]]*keep_real .*&&[[:space:]]*$/ {
      print FILENAME ":" FNR ": links without keep_real: a real file there would be replaced for good"
    }
    { prev = $0 }
  ' zsh/functions/*.zsh
  local -a links=(${(f)"$(grep -h '^[^#]*ln -sfn' zsh/functions/*.zsh)"})
  note=$(count $#links link)
}

check "no tokens or private keys" check_secrets
check "only example and noreply email addresses" check_emails
check "the private files are ignored and untracked" check_private
check "config/claude names nothing of this Mac or repo" check_claude_global
check "nothing reaches for Intel Homebrew or Rosetta" check_arm64
check "no code deletes for good" check_deletes
check "every link the setup makes keeps a real file" check_links_keep
