---
name: ship
description: Finish the current work - check it against the project's own rules, run its checks, commit it on a branch and, with "pr", push and open a pull request. Use only when the user runs /ship.
argument-hint: "[pr] [what the change is about]"
disable-model-invocation: true
---

The user asked to ship the work in this checkout. Running /ship is their go-ahead to commit; push and open a
pull request only when the arguments contain `pr`. Arguments: $ARGUMENTS

1. **Branch.** If the checkout is on the default branch, create a branch named after the change
   (`<type>/<short-name>`) and continue there. Never commit to the default branch.
2. **Scope.** Read `git status` and the full diff, untracked files included. Ship only what belongs to this
   change; leave unrelated edits unstaged and say so. Stop and ask if you can't tell which is which.
3. **Project rules.** Read the project's `CLAUDE.md` files and its contributing docs. If they ask for
   something alongside a change (docs, a changelog, a lock file, tests), check it is in the diff; add what is
   missing.
4. **Checks.** Run the checks the project defines (its `CLAUDE.md`, README, Makefile, package.json scripts or
   CI workflow), only the ones that are fast and local. Fix what fails because of this change; if a failure is
   unrelated or the fix isn't clear, stop and report it instead of committing.
5. **Commit.** Use the project's commit style: what its `CLAUDE.md` says, else what `git log` shows. The
   subject says what changed, the body what and why. Split into several commits only where the diff holds
   clearly separate changes.
6. **Pull request** (only with `pr`): push the branch and open a PR with `gh pr create`; the title is the
   commit subject (or a summary of several), the body says what and why and how it was checked. Pushing may
   wait for the user to authenticate; tell them.
7. **Report** in a few lines: the commits (hash and subject), which checks ran and passed, the PR link, and
   anything left out or unresolved.
