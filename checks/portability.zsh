# Portability checks: nothing in the repo belongs to one Mac, so every Mac can take all of it (docs/setup.md,
# "Several Macs"). No path into one user's home, nothing naming this Mac, none of the words this Mac lists as
# never to be published (a company, a work email, a work host), and no commit waiting to be pushed with an
# email other than the shared one. Sourced by check_dotfiles; lib.zsh has the helpers and indexes.

# forbidden: the words ~/.config/dotfiles/forbidden lists, one per line (# starts a comment), lower-cased.
# The list stays on the Mac, since the words themselves mustn't be in the repo. DOTFILES_FORBIDDEN names
# another list, for checks/mutate's breaks, which mustn't depend on what this Mac's list holds.
forbidden_words() {
  local list=${DOTFILES_FORBIDDEN:-~/.config/dotfiles/forbidden} line
  [[ -r $list ]] || return 0
  for line in "${(@f)$(<$list)}"; do
    line=${${line%%\#*}//[[:space:]]##/ }
    line=${${line# }% }
    [[ -n $line ]] && print -r -- ${(L)line}
  done
}

# this Mac's names: its hostname, its Bonjour name and the name setup_machine gave it, each at least 6
# characters long, so that a Mac named `work` doesn't fail every file that says "work"
mac_names() {
  local -a names=(${HOST%%.*} ${${(f)"$(scutil --get LocalHostName 2> /dev/null)"}})
  [[ -r ~/.config/dotfiles/name ]] && names+=$(<~/.config/dotfiles/name)
  print -rl -- ${(u)${(L)${(M)names:#??????*}}}
}

# where <problem>: grep -n's lines as "file:line: <problem>", without the line itself (a forbidden word
# shouldn't land in CI's log either)
where() {
  awk -F: -v problem="$1" '{ print $1 ":" $2 ": " problem }'
}

# home paths: no file names a path in one user's home (/Users/<name>/…, /home/<name>/…); ~ and $HOME work on
# every Mac. A path after a word or a variable ($t/home/x, example.com/home) isn't one. Not checks/mutate, whose
# breaks add such paths on purpose.
check_home_paths() {
  grep -nE '(^|[^A-Za-z0-9_.~$/{}-])/(Users|home)/[A-Za-z]' -- ${text_files:#checks/mutate} |
    where "a path in one user's home; ~ or \$HOME works on every Mac"
  note=$(count $#text_files file)
}

# this Mac: no file names this Mac or a word on its forbidden list (whole words, any case). allowed_signers
# names every Mac's keys on purpose, so the Mac's names may be there, its forbidden words not.
check_this_mac() {
  local -a names=(${(f)"$(mac_names)"}) words=(${(f)"$(forbidden_words)"})
  local -a others=(${text_files:#config/git/allowed_signers})
  (( $#names )) && grep -nwiF ${names/#/-e} -- $others | where "names this Mac (${(j:, :)names})"
  (( $#words )) && grep -nwiF ${words/#/-e} -- $text_files | where "a word on ~/.config/dotfiles/forbidden"
  note="$(count $#names name), $(count $#words "forbidden word")"
}

# commits: the commits no remote has yet (the ones a push would publish) use the email of
# config/git/.gitconfig, as author and as committer, and their messages name neither this Mac nor a forbidden
# word. A work email (from a work repo's includeIf) or a made-up one (user@host.local, when git had none)
# would otherwise reach GitHub with them.
check_commits() {
  local email=$(git config --file config/git/.gitconfig user.email)
  local -a commits=(${(f)"$(git rev-list HEAD --not --remotes 2> /dev/null)"})
  local -a words=(${(f)"$(mac_names)"} ${(f)"$(forbidden_words)"})
  local sha author committer subject message
  for sha in $commits; do
    IFS=$'\t' read -r author committer subject < <(git log -1 --format=$'%ae\t%ce\t%s' $sha)
    [[ $author == $email ]] || print -r -- "${sha[1,7]} $subject: author email $author, not $email"
    [[ $committer == $email ]] || print -r -- "${sha[1,7]} $subject: committer email $committer, not $email"
    (( $#words )) || continue
    message=$(git log -1 --format=%B $sha)
    print -r -- $message | grep -qwiF ${words/#/-e} &&
      print -r -- "${sha[1,7]} $subject: its message names this Mac or a forbidden word"
  done
  note="$(count $#commits "unpushed commit")"
}

group "Portability: nothing in the repo belongs to one Mac"
check "no paths into one user's home" check_home_paths
check "nothing names this Mac or a forbidden word" check_this_mac
check "unpushed commits use the shared email" check_commits
