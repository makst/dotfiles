# Commit checks: the commits a push would publish (commits_to_check, lib.zsh) keep to CLAUDE.md, "Style": a
# `type(scope): summary` subject, a body saying what and why, signed with a key in config/git/allowed_signers,
# and no "Generated with" line, since the only Claude line is the Co-Authored-By trailer. Before a push they
# can still be fixed with an amend or a rebase. The email is checked with the portability ones. Sourced by
# check_dotfiles; lib.zsh has the helpers.

# messages: the subject is `type(scope): summary` (feat, fix, refactor, docs, chore; the scope is the tool and
# may be left out for a change across tools), a blank line, then a body besides the trailers
check_messages() {
  local -a commits=(${(f)"$(commits_to_check)"})
  local sha subject body
  for sha in $commits; do
    subject=$(git log -1 --format=%s $sha)
    [[ $subject == (feat|fix|refactor|docs|chore)(|\([a-z0-9/_.,-]##\))!#:\ ?* ]] ||
      print -r -- "${sha[1,7]} $subject: the subject isn't type(scope): summary"
    body=$(git log -1 --format=%b $sha | grep -vE '^([A-Za-z-]+: .*)?$')
    [[ -n $body ]] || print -r -- "${sha[1,7]} $subject: no body saying what and why"
    git log -1 --format=%B $sha | grep -qiE '^[^A-Za-z]*generated with' &&
      print -r -- "${sha[1,7]} $subject: a \"Generated with\" line; the Co-Authored-By trailer is enough"
  done
  note=$(count $#commits commit)
}

# signatures: each commit is signed with a key config/git/allowed_signers lists (git's %G? is G), so GitHub
# shows it verified and a commit made without the signing key doesn't slip out
check_signatures() {
  local -a commits=(${(f)"$(commits_to_check)"})
  (( $#commits )) || { note="0 commits"; return 0 }
  (( $+commands[ssh-keygen] )) || { print "ssh-keygen not installed"; return 2 }
  git -c gpg.ssh.allowedSignersFile=$repo/config/git/allowed_signers log --no-walk=unsorted \
    --format=$'%G?\t%h %s' $commits | awk -F'\t' '$1 != "G" { print $2 ": not signed with a key in allowed_signers (" $1 ")" }'
  note=$(count $#commits commit)
}

group "Commits: what a push would publish keeps to the conventions"
check "commit messages are type(scope): summary with a body" check_messages
check "commits are signed with a known key" check_signatures
