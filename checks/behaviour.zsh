# Behaviour checks: the scripts that run on their own (zsh's start, Claude Code's hooks and status line) do what
# they should. Claude Code's run with only zsh, jq, git and gh on PATH besides the system's own tools, since
# config/claude must work on any machine with just those. Also the parts that could lose work or break the setup
# if rewritten from their edge, each tried on its own in a throwaway repo, HOME or tmux server: the agent
# functions (agent_done, _agent_worktree, agent_land), the GitHub watcher with its inbox list, and the agents'
# state with the order agents and next-agent show it in. Those take a few hundred milliseconds each, so `early`
# starts them in the background and the checks collect them. Sourced by check_dotfiles.

mkdir -p $tmp/bin
for tool in zsh jq git gh; do
  (( $+commands[$tool] )) && ln -s $commands[$tool] $tmp/bin/$tool
done
minimal_path=$tmp/bin:/usr/bin:/bin:/usr/sbin:/sbin

# zsh: the repo's .zshrc starts an interactive zsh without an error. Without a terminal, zle can't start, and
# the widgets that need it say so; that's the only message allowed. On CI none of the Homebrew tools exist,
# which the config has to cope with too. TERM is set as in a terminal: CI may have none or a dumb one, where
# starship refuses to start.
check_zsh_start() {
  TERM=xterm-256color ZDOTDIR=$repo zsh -i -c exit < /dev/null > /dev/null 2> $tmp/zsh.err
  grep -v "can't change option: zle" $tmp/zsh.err
  return 0
}

# zsh's functions find the repo in a shell that has them without having read .zshrc: Claude Code's shell, a
# snapshot of the interactive one, keeps only exported variables. The child zsh stands in for it.
check_zsh_exports() {
  # without the variable it may already have (Claude Code's shell exports it), which would keep it exported
  # even if .zshrc stopped exporting it
  local got=$(env -u real_script_dir TERM=xterm-256color ZDOTDIR=$repo zsh -i -c \
    'zsh -fc "print -r -- \$real_script_dir"' < /dev/null 2> /dev/null)
  [[ $got == $repo ]] || print -r -- "a child shell doesn't get real_script_dir (got '$got'): export it in .zshrc"
  return 0
}

# no-recursive-rm: every case in checks/rm-hook.cases, run in parallel through the hook as Claude Code calls it
check_rm_hook() {
  local line i
  local -a want commands
  while IFS= read -r line; do
    [[ $line == (\#*|) ]] && continue
    want+=${line%% *}
    commands+=${${line#* }//\\n/$'\n'}
  done < checks/rm-hook.cases
  # each case's input as Claude Code sends it, all made by one jq
  i=0
  jq -nc '$ARGS.positional[] | {tool_input: {command: .}}' --args -- $commands | while IFS= read -r line; do
    print -r -- $line > $tmp/rm.in.$(( ++i ))
  done
  for i in {1..$#commands}; do
    PATH=$minimal_path config/claude/hooks/no-recursive-rm.sh < $tmp/rm.in.$i > $tmp/rm.$i 2>&1 &
  done
  wait
  local got out decision=
  local -i blocked=0
  for i in {1..$#commands}; do
    out=$(<$tmp/rm.$i)
    if [[ -z $out ]]; then
      got=allow
    elif [[ $out == *'"permissionDecision": "deny"'* ]]; then
      got=block
      blocked+=1
      [[ -n $decision ]] || decision=$out
    else
      print -r -- "${commands[i]//$'\n'/\\n}: the hook printed something other than its decision: $out"
      continue
    fi
    [[ $got == $want[i] ]] || print -r -- "should $want[i]: ${commands[i]//$'\n'/\\n}"
  done
  # the decision itself, in the shape Claude Code reads
  [[ -z $decision ]] ||
    jq -e '.hookSpecificOutput | .hookEventName == "PreToolUse" and .permissionDecision == "deny" and
      (.permissionDecisionReason | length > 0)' <<< $decision > /dev/null ||
    print -r -- "the hook's decision isn't what Claude Code expects: $decision"
  note="blocks $blocked, allows $(( $#commands - blocked ))"
}

# format: without a formatter on PATH, or in a project that doesn't configure one, the file stays as it is and
# the hook says nothing; with shfmt, a project's .editorconfig gets its shell scripts formatted, and only then
check_format_hook() {
  local project=$tmp/project file out
  local messy=$'if true; then\necho hi\nfi' json='{"a":1}'
  mkdir -p $project
  print -r -- $'[*]\nindent_style = space\nindent_size = 2' > $project/.editorconfig
  print -r -- $messy > $project/x.sh
  print -r -- $json > $project/x.json
  for file in x.sh x.json missing.txt; do
    out=$(jq -n --arg f $project/$file '{tool_input: {file_path: $f}}' |
      PATH=$minimal_path config/claude/hooks/format.sh 2>&1) || print -r -- "$file: the hook failed"
    [[ -n $out ]] && print -r -- "$file: $out"
  done
  [[ $(<$project/x.sh) == $messy ]] || print "x.sh changed with no formatter on PATH"
  out=$(jq -n --arg f $project/x.json '{tool_input: {file_path: $f}}' | config/claude/hooks/format.sh 2>&1)
  [[ -z $out && $(<$project/x.json) == $json ]] || print "x.json changed in a project without a prettier config"
  note="without formatters"
  (( $+commands[shfmt] )) || return 0
  mkdir -p $tmp/bare
  print -r -- $messy > $tmp/bare/x.sh
  jq -n --arg f $tmp/bare/x.sh '{tool_response: {filePath: $f}}' | config/claude/hooks/format.sh
  [[ $(<$tmp/bare/x.sh) == $messy ]] || print "shfmt formatted x.sh in a project without an .editorconfig"
  jq -n --arg f $project/x.sh '{tool_response: {filePath: $f}}' | config/claude/hooks/format.sh
  [[ $(<$project/x.sh) == $'if true; then\n  echo hi\nfi' ]] ||
    print "shfmt didn't format x.sh in a project with an .editorconfig"
  note+=" and with shfmt"
}

# bell: outside tmux, or for a pane tmux doesn't know, it does nothing and says nothing
check_bell_hook() {
  local out
  out=$(env -u TMUX_PANE PATH=$minimal_path config/claude/hooks/bell.sh < /dev/null 2>&1) ||
    print "outside tmux: the hook failed"
  [[ -n $out ]] && print -r -- "outside tmux: $out"
  out=$(TMUX_PANE=%999 PATH=$minimal_path config/claude/hooks/bell.sh < /dev/null 2>&1) ||
    print "in an unknown pane: the hook failed"
  [[ -n $out ]] && print -r -- "in an unknown pane: $out"
  note="outside tmux, unknown pane"
}

# status line: what it shows for a full session, a bare one and a heavy one (times relative to now, so the
# resets and the cache's expiry always read the same), and the colours of the warnings
check_statusline() {
  local name out plain
  local -A input expect
  input[full]='{workspace: {current_dir: "/tmp"}, model: {display_name: "Opus 5.5"}, effort: {level: "medium"},
    context_window: {used_percentage: 7.4, context_window_size: 1000000,
      current_usage: {input_tokens: 2, cache_creation_input_tokens: 250, cache_read_input_tokens: 69153}},
    rate_limits: {five_hour: {used_percentage: 3, resets_at: (now + 17327)},
      seven_day: {used_percentage: 24.6, resets_at: (now + 343727 | todate)}},
    prompt_cache: {warm: true, expires_at: (now + 3000)}}'
  expect[full]='/tmp  Opus 5.5 medium  ctx 7% 69k  cache 50m  5h 3% 5h  7d 24% 4d'
  input[bare]='{cwd: "/tmp", model: {display_name: "Sonnet 5.5"}}'
  expect[bare]='/tmp  Sonnet 5.5  ctx 0%'
  input[heavy]='{workspace: {current_dir: "/tmp"}, model: {display_name: "Opus 5.5"},
    context_window: {used_percentage: 82, context_window_size: 1500000},
    rate_limits: {five_hour: {used_percentage: 91, resets_at: (now + 1500)},
      seven_day: {used_percentage: 55, resets_at: (now + 7200)}},
    prompt_cache: {warm: false}}'
  expect[heavy]='/tmp  Opus 5.5  ctx 82% 1.2M  cache cold  5h 91% 25m  7d 55% 2h'
  for name in full bare heavy; do
    jq -n $input[$name] | PATH=$minimal_path config/claude/statusline.sh > $tmp/statusline.$name \
      2> $tmp/statusline.$name.err &
  done
  wait
  for name in full bare heavy; do
    out=$(<$tmp/statusline.$name)
    [[ -s $tmp/statusline.$name.err ]] && print -r -- "$name: $(<$tmp/statusline.$name.err)"
    plain=${out//$'\e'\[[0-9;]#m/}
    [[ $plain == $expect[$name] ]] || print -r -- "$name session: shows '$plain', should show '$expect[$name]'"
    [[ $name == heavy ]] || continue
    [[ $out == *$'\e[31m'"ctx 82%"* ]] || print "heavy session: a context over 80% isn't red"
    [[ $out == *$'\e[31m'"cache cold"* ]] || print "heavy session: a cold cache isn't red"
    [[ $out == *$'\e[33m'"7d 55%"* ]] || print "heavy session: a limit over 50% isn't yellow"
  done
  note="3 sessions"
}

# the git hooks and reload_dotfiles, in a throwaway repo with the hooks and zsh/functions, two commits and
# stand-ins for tmux, Ghostty and AeroSpace that log their calls: zsh functions in its HOME's .zshenv, which the
# hook's zsh reads too (macOS takes ~150 ms to first run a new executable). A change to tmux.conf and Ghostty's
# config reloads those two and not AeroSpace, a change to .zshrc and the Brewfile lists what's left, no change
# does nothing. The hooks do nothing while the HOME's .zshrc doesn't link into the repo, and reload after a
# switch and a merge once it does.
check_reload() {
  local t=$tmp/reload out
  mkdir -p $t/repo/{zsh,config/{tmux,ghostty,aerospace}} $t/home
  print -r -- "for c in tmux pgrep pkill aerospace; functions[\$c]='print -r -- \$0 \$* >> $t/calls'
ghostty() { print 'Ghostty 1.4.0' }" > $t/home/.zshenv
  cp -RP .githooks $t/repo/ && cp -R zsh/functions $t/repo/zsh/
  local -a git=(git -C $t/repo -c user.name=t -c user.email=t@t -c commit.gpgsign=false)
  {
    git init -q -b main $t/repo && $git config core.hooksPath .githooks &&
      touch $t/repo/{.zshrc,Brewfile,config/tmux/tmux.conf,config/ghostty/config,config/aerospace/aerospace.toml} &&
      $git add -A && $git commit -qm a &&
      print x | tee $t/repo/{.zshrc,Brewfile,config/tmux/tmux.conf,config/ghostty/config} > /dev/null &&
      print "# not a link: keep_real x && ln -sfn" >> $t/repo/zsh/functions/setup.zsh &&
      $git commit -qam b
  } > /dev/null 2>&1 || { print "couldn't make the test repo"; return }
  reload() { HOME=$t/home zsh -c "real_script_dir=$t/repo; for f in $t/repo/zsh/functions/*.zsh; do source \$f; done; reload_dotfiles $1" }
  calls() { [[ -e $t/calls ]] && <$t/calls; rm -f $t/calls }

  out=$(reload HEAD~1)
  local log=$(calls)
  [[ $log == *'tmux source-file'* ]] || print "tmux.conf changed, but tmux wasn't reloaded"
  [[ $log == *'pkill -USR2 -x ghostty'* ]] || print "Ghostty's config changed, but Ghostty wasn't reloaded"
  [[ $log == *'aerospace reload-config'* ]] && print "AeroSpace was reloaded, but its config didn't change"
  [[ $out == *'exec zsh'* && $out == *setup_brew* ]] || print -r -- "the list of what's left misses zsh or the Brewfile: $out"
  [[ $out == *setup_dotfiles* ]] && print -r -- "no setup step links anything new, but it asks for setup_dotfiles: $out"
  out=$(reload HEAD)
  [[ -z $out$(calls) ]] || print -r -- "nothing changed, but it did something: $out"

  # the hooks: a switch back to the first commit, outside the live setup, then a switch and a merge inside it
  HOME=$t/home $git switch -q -c old HEAD~1 > /dev/null 2>&1
  [[ -z $(calls) ]] || print "the hook acted in a checkout the setup doesn't link to"
  ln -s $t/repo/.zshrc $t/home/.zshrc
  HOME=$t/home $git switch -q main > /dev/null 2>&1
  [[ $(calls) == *'tmux source-file'* ]] || print "a branch switch didn't reload tmux"
  HOME=$t/home $git switch -q old > /dev/null 2>&1 && calls > /dev/null
  HOME=$t/home $git merge -q --ff-only main > /dev/null 2>&1
  [[ $(calls) == *'tmux source-file'* ]] || print "a merge didn't reload tmux"
}

# link_claude_skills, in a throwaway HOME and repo with two skills: a skill gets linked, a real copy in its
# place goes to the Trash, the link of a skill the repo no longer has goes, and a dangling link to elsewhere
# (a skill of the user's own) stays.
check_skill_links() {
  local t=$tmp/skills s=$tmp/skills/home/.claude/skills
  mkdir -p $t/repo/config/claude/skills/{new,copied}/ $t/home/.Trash $s/copied
  ln -s $t/repo/config/claude/skills/gone $s/gone
  ln -s $t/home/moved $s/own
  HOME=$t/home zsh -c "real_script_dir=$t/repo; source zsh/functions/setup.zsh
    source zsh/functions/claude.zsh; link_claude_skills" > /dev/null ||
    print "link_claude_skills failed"
  [[ -L $s/new && $s/new -ef $t/repo/config/claude/skills/new ]] || print "a new skill wasn't linked"
  [[ -L $s/copied ]] || print "a real copy in a skill's place wasn't replaced by the link"
  [[ -n $(print $t/home/.Trash/copied-*(N)) ]] || print "the real copy didn't go to the Trash"
  [[ -L $s/gone ]] && print "the link of a skill the repo no longer has is still there"
  [[ -L $s/own ]] || print "a link that doesn't point into the repo, dangling, was removed"
  note="4 skills"
}

# early <name> <function>: runs the function in the background from now on, since the agent, GitHub and tmux
# checks below each set up their own repo, state or server and take a few hundred milliseconds. Its output and
# exit status wait in $tmp/early.<name>.* for early_result; disowned, so the `wait` of the checks above doesn't
# block on it.
early() {
  local name=$1 fn=$2
  (
    local started=$EPOCHREALTIME
    $fn > $tmp/early.$name 2>&1
    local rc=$?
    print -r -- "$(printf %.0f $(( (EPOCHREALTIME - started) * 1000 )))" > $tmp/early.$name.ms
    print -r -- $rc > $tmp/early.$name.rc.new && mv $tmp/early.$name.rc.new $tmp/early.$name.rc
  ) &!
}

# early_result <name> <what>: waits for the function early started, prints its problems and returns its status
# (2 skips the check); sets `note` of the check that calls it to <what> and how long the background run took
early_result() {
  local i
  for i in {1..1500}; do
    [[ -e $tmp/early.$1.rc ]] && break
    sleep 0.02
  done
  [[ -e $tmp/early.$1.rc ]] || { print "the background run of $1 never finished"; return 1 }
  cat $tmp/early.$1
  note="$2, $(<$tmp/early.$1.ms) ms in the background"
  return $(<$tmp/early.$1.rc)
}

# agent_helpers: writes $tmp/agent-helpers.zsh, what the agent checks' scripts source: HOME, git identity and the
# Trash in a throwaway $T/home, zsh/functions/claude.zsh, a repo $r (branch main, origin a bare repo with
# origin/HEAD set) and the way `agent` makes a worktree, so each case needs only its own few lines. A case's
# repo is its own, so the cases of a script run at the same time.
agent_helpers() {
  cat > $tmp/agent-helpers.zsh <<'EOF'
unsetopt bg_nice  # a sandbox (Claude Code's) can't lower the priority of background jobs
export HOME=$T/home
unset TMUX
mkdir -p $HOME/.Trash
print -r -- $'[user]\n\tname = t\n\temail = t@t\n[commit]\n\tgpgsign = false' > $HOME/.gitconfig
source $real_script_dir/zsh/functions/claude.zsh

# bad <problem>: one problem line, named for the case
bad() { print -r -- "$name: $*" }
# mkrepo: $r with one commit on main, pushed to $t/origin.git
mkrepo() {
  git init -q --bare -b main $t/origin.git && git init -q -b main $r || return
  print .env > $r/.gitignore
  git -C $r add .gitignore && git -C $r commit -qm first &&
    git -C $r remote add origin $t/origin.git && git -C $r push -q origin main &&
    git -C $r remote set-head origin main > /dev/null
}
# mkagent <name>: a worktree the way `agent` makes it (claude -w): worktree-<name> from main
mkagent() { git -C $r worktree add -q -b worktree-$1 $r/.claude/worktrees/$1 main }
wt() { print -r -- $r/.claude/worktrees/$1 }
tip_of() { git -C $1 rev-parse HEAD }
# save <dir> <file> [text]: commits <file> in <dir> ("work on <file>")
save() { print -r -- ${3:-$2} > $1/$2; git -C $1 add $2 && git -C $1 commit -qm "work on $2" }
has_branch() { git -C $r rev-parse -q --verify refs/heads/worktree-$1 > /dev/null }
saved_ref() { git -C $r rev-parse -q --verify refs/agents/$1 }
# gone <agent>: problems if the agent's worktree, checkout or branch is still there
gone() {
  [[ -d $(wt $1) ]] && bad "the worktree's folder is still there"
  git -C $r worktree list --porcelain | grep -q "$(wt $1)\$" && bad "git still lists the worktree"
  has_branch $1 && bad "the branch is still there"
  return 0
}
# runcases <case…>: each case_<name> in a repo of its own, all at once; their problems in order
runcases() {
  local c
  for c in "$@"; do
    ( name=$c t=$T/$c r=$T/$c/repo; mkdir -p $t; mkrepo && cd $r && case_$c || bad "couldn't make the test repo" ) \
      > $T/out.$c 2>&1 &
  done
  wait
  for c in "$@"; do cat $T/out.$c; done
}
EOF
}

# agent_done (zsh/functions/claude.zsh): removes a worktree only when nothing would be lost
run_agent_done() {
  local t=$tmp/agent-done
  mkdir -p $t
  cat > $t/run.zsh <<'EOF'
source $H
case_dirty() {
  mkagent a; touch $(wt a)/new
  agent_done a > /dev/null 2>&1; rc=$?
  (( rc == 1 )) || bad "uncommitted changes: returns $rc, not 1"
  [[ -d $(wt a) ]] && has_branch a || bad "uncommitted changes: the worktree or its branch is gone"
  [[ -z $(git -C $r for-each-ref refs/agents) ]] || bad "uncommitted changes: refs/agents has an entry"
}
case_unmerged() {
  mkagent a; save $(wt a) a.txt
  err=$(agent_done a 2>&1 > /dev/null); rc=$?
  (( rc == 1 )) || bad "an unmerged commit: returns $rc, not 1"
  [[ $err == *'work on a.txt'* ]] || bad "an unmerged commit: stderr doesn't show its subject: $err"
  [[ -d $(wt a) ]] && has_branch a || bad "an unmerged commit: the worktree or its branch is gone"
  [[ -z $(git -C $r for-each-ref refs/agents) ]] || bad "an unmerged commit: refs/agents has an entry"
}
case_forced() {
  mkagent a; save $(wt a) a.txt; tip=$(tip_of $(wt a))
  agent_done --force a > /dev/null 2>&1 || bad "--force on an unmerged commit: returns $?"
  gone a
  [[ $(saved_ref a) == $tip ]] || bad "--force: refs/agents/a isn't the old tip"
}
case_merged() {
  mkagent a; save $(wt a) a.txt; tip=$(tip_of $(wt a))
  git -C $r merge -q --ff-only worktree-a
  agent_done a > /dev/null 2>&1 || bad "a commit merged into main: returns $?"
  gone a
  [[ $(saved_ref a) == $tip ]] || bad "a merged commit: refs/agents/a isn't the tip"
}
case_pushed() {
  mkagent a; save $(wt a) a.txt; tip=$(tip_of $(wt a))
  git -C $(wt a) push -q origin HEAD:main
  git -C $r merge-base --is-ancestor $tip main && bad "setup: local main has the commit"
  agent_done a > /dev/null 2>&1 || bad "a commit only in origin/main: returns $?"
  gone a
  [[ $(saved_ref a) == $tip ]] || bad "a commit only in origin/main: refs/agents/a isn't the tip"
}
case_ignored() {
  mkagent a; print secret > $(wt a)/.env
  agent_done a > /dev/null 2>&1 || bad "a worktree with an ignored file: returns $?"
  gone a
  local -a kept=($HOME/.Trash/agent-a-*/.env(N))
  [[ $#kept == 1 && $(<$kept[1]) == secret ]] || bad "the worktree isn't in the Trash with its .env"
}
case_list() {
  mkagent fresh; mkagent dirty; touch $(wt dirty)/new
  mkagent two; save $(wt two) a.txt; save $(wt two) b.txt
  mkagent part; save $(wt part) c.txt; touch $(wt part)/new
  local -a lines=(${(f)"$(agent_done)"})
  local want
  for want in "fresh  (worktree-fresh: merged)" \
    "dirty  (worktree-dirty: merged, uncommitted changes)" \
    "two  (worktree-two: 2 commits not in main)" \
    "part  (worktree-part: 1 commit not in main, uncommitted changes)"; do
    (( $lines[(Ie)$want] )) || bad "the list lacks '$want'; it has: ${(j:; :)lines}"
  done
}
runcases dirty unmerged forced merged pushed ignored list
EOF
  H=$tmp/agent-helpers.zsh T=$t real_script_dir=$repo zsh -f $t/run.zsh
}

# _agent_worktree: brings back what agent_done left (docs/claude.md, "Going back to an agent")
run_agent_resume() {
  local t=$tmp/agent-resume
  mkdir -p $t
  cat > $t/run.zsh <<'EOF'
source $H
case_dropped() {
  mkagent a; save $(wt a) a.txt; tip=$(tip_of $(wt a))
  agent_done --force a > /dev/null 2>&1
  _agent_worktree $r a > /dev/null 2>&1 || bad "returns $?"
  [[ $(git -C $(wt a) branch --show-current 2> /dev/null) == worktree-a ]] || bad "not on worktree-a"
  [[ $(tip_of $(wt a) 2> /dev/null) == $tip ]] || bad "after --force: not at the saved tip"
}
case_merged() {
  mkagent a; save $(wt a) a.txt
  git -C $r merge -q --ff-only worktree-a
  agent_done a > /dev/null 2>&1
  save $r later.txt
  _agent_worktree $r a > /dev/null 2>&1 || bad "returns $?"
  [[ $(git -C $(wt a) branch --show-current 2> /dev/null) == worktree-a ]] || bad "not on worktree-a"
  [[ $(tip_of $(wt a) 2> /dev/null) == $(tip_of $r) ]] || bad "after a merge: not from main's tip"
}
case_kept() {
  mkagent a; save $(wt a) a.txt; tip=$(tip_of $(wt a))
  git -C $r worktree remove $(wt a)
  _agent_worktree $r a > /dev/null 2>&1 || bad "returns $?"
  [[ $(git -C $(wt a) branch --show-current 2> /dev/null) == worktree-a ]] || bad "not on worktree-a"
  [[ $(tip_of $(wt a) 2> /dev/null) == $tip ]] || bad "with its branch still there: not at the branch's tip"
}
runcases dropped merged kept
EOF
  H=$tmp/agent-helpers.zsh T=$t real_script_dir=$repo zsh -f $t/run.zsh
}

# agent_land (zsh/functions/claude.zsh): lands only a clean, rebased, checked branch, and leaves the agent's
# branch as it was when it can't
run_agent_land() {
  local t=$tmp/agent-land
  mkdir -p $t
  cat > $t/run.zsh <<'EOF'
source $H
case_lands() {
  mkagent a; save $(wt a) f.txt; tip=$(tip_of $(wt a))
  agent_land --no-check a > /dev/null 2>&1 || bad "--no-check on a clean branch: returns $?"
  [[ $(tip_of $r) == $tip ]] || bad "main isn't fast-forwarded to the branch"
  [[ -e $r/f.txt ]] || bad "the main checkout's files didn't move"
  gone a
}
case_no_check_set() {
  mkagent a; save $(wt a) f.txt; main=$(tip_of $r)
  err=$(agent_land a 2>&1 > /dev/null); rc=$?
  (( rc == 1 )) || bad "without agent.check: returns $rc, not 1"
  [[ $err == *agent.check* ]] || bad "without agent.check: stderr doesn't say how to set it: $err"
  [[ $(tip_of $r) == $main && -d $(wt a) ]] || bad "without agent.check: main moved or the worktree went"
}
case_check_fails() {
  mkagent a; save $(wt a) f.txt; main=$(tip_of $r); git -C $r config agent.check false
  agent_land a > /dev/null 2>&1; rc=$?
  (( rc == 1 )) || bad "with a failing agent.check: returns $rc, not 1"
  [[ $(tip_of $r) == $main && -d $(wt a) ]] || bad "with a failing agent.check: main moved or the worktree went"
}
case_check_runs_in_worktree() {
  mkagent a; save $(wt a) f.txt; tip=$(tip_of $(wt a)); git -C $r config agent.check 'test -f f.txt'
  agent_land a > /dev/null 2>&1 || bad "agent.check runs outside the agent's worktree: returns $?"
  [[ $(tip_of $r) == $tip ]] || bad "a passing agent.check: main isn't at the branch"
}
case_conflict() {
  mkagent a; save $(wt a) conf.txt theirs; tip=$(tip_of $(wt a)); save $r conf.txt ours
  err=$(agent_land --no-check a 2>&1 > /dev/null); rc=$?
  (( rc == 1 )) || bad "a conflict: returns $rc, not 1"
  [[ $err == *conf.txt* ]] || bad "a conflict: stderr doesn't name the file: $err"
  [[ $(tip_of $(wt a)) == $tip ]] || bad "a conflict: the agent's branch moved"
  [[ -z $(git -C $(wt a) status --porcelain) ]] || bad "a conflict: the worktree isn't clean"
  local gd=$(git -C $(wt a) rev-parse --absolute-git-dir)
  [[ -e $gd/rebase-merge || -e $gd/rebase-apply ]] && bad "a conflict: the rebase is still in progress"
  [[ $(git -C $(wt a) branch --show-current) == worktree-a ]] || bad "a conflict: the worktree is off its branch"
}
case_behind() {
  mkagent p; save $(wt p) p.txt; git -C $(wt p) push -q origin HEAD:main
  mkagent a; save $(wt a) f.txt; main=$(tip_of $r)
  err=$(agent_land --no-check a 2>&1 > /dev/null); rc=$?
  (( rc == 1 )) || bad "main behind origin/main: returns $rc, not 1"
  [[ $err == *pull* ]] || bad "main behind origin/main: stderr doesn't say to pull: $err"
  [[ $(tip_of $r) == $main && -d $(wt a) ]] || bad "main behind origin/main: main moved or the worktree went"
}
runcases lands no_check_set check_fails check_runs_in_worktree conflict behind
EOF
  H=$tmp/agent-helpers.zsh T=$t real_script_dir=$repo zsh -f $t/run.zsh
}

# config/github/watch: notices what changed since its last run and nothing else, and keeps its last good state
# when GitHub can't be asked. gh is a stub that runs the --jq filter the watcher passes over a raw fixture, as
# gh does, so the filters are tested too; terminal-notifier is a stub that logs its arguments; no tmux.
run_github_watch() {
  local t=$tmp/watch out
  local state=$t/state/github/state.json
  mkdir -p $t/stubs $t/home
  cat > $t/stubs/gh <<'EOF'
#!/bin/sh
[ -e "$T/gh.fail" ] && { echo "gh: boom" >&2; exit 1; }
filter= prev=
for a in "$@"; do
  [ "$prev" = --jq ] && filter=$a
  prev=$a
done
case "$*" in
  *graphql*) jq -c "$filter" "$T/graphql.json" ;;
  *notifications*) jq -c "$filter" "$T/notifications.json" ;;
  *) exit 1 ;;
esac
EOF
  print -r -- $'#!/bin/sh\necho "$*" >> "$T/notified"' > $t/stubs/terminal-notifier
  chmod +x $t/stubs/*
  # pr <number> <checks state> [review decision]: a pull request as GitHub's GraphQL answers it
  pr() {
    jq -nc --arg n $1 --arg s $2 --arg r "${3:-}" '{number: ($n | tonumber), title: "pr \($n)",
      url: "https://github.com/o/r/pull/\($n)", isDraft: false,
      reviewDecision: (if $r == "" then null else $r end), headRefName: "b\($n)",
      repository: {nameWithOwner: "o/r"}, commits: {nodes: [{commit: {statusCheckRollup: {state: $s}}}]}}'
  }
  # note <id> <reason>: an unread notification on issue <id>, as the REST API answers it
  note() {
    jq -nc --arg id $1 --arg r $2 '{id: $id, reason: $r, updated_at: "2026-01-01T00:00:00Z",
      subject: {title: "thread \($id)", url: "https://api.github.com/repos/o/r/issues/\($id)"},
      repository: {full_name: "o/r", url: "https://api.github.com/repos/o/r"}}'
  }
  # fixtures <mine prs> <asked prs> <notes>: each a comma-separated list of the above
  fixtures() {
    jq -nc --argjson m "[$1]" --argjson a "[$2]" \
      '{data: {mine: {nodes: $m}, asked: {nodes: $a}}}' > $t/graphql.json
    print -r -- "[$3]" > $t/notifications.json
  }
  # run_watch: one run, as the LaunchAgent does it; only the stubs and the system's tools on PATH
  run_watch() { T=$t XDG_STATE_HOME=$t/state HOME=$t/home PATH=$t/stubs:$minimal_path config/github/watch }

  fixtures "$(pr 1 SUCCESS)" "$(pr 3 PENDING)" "$(note 7 comment)"
  run_watch || print "the first run exits $?, not 0"
  [[ -e $t/notified ]] && print "the first run only records what's there, but it notified: $(<$t/notified)"
  jq -e 'has("mine") and has("asked") and has("notes") and has("at")' $state > /dev/null 2>&1 ||
    print "the state file lacks mine, asked, notes or at"
  run_watch
  [[ -e $t/notified ]] && print "nothing changed, but it notified: $(<$t/notified)"

  fixtures "$(pr 1 FAILURE)" "$(pr 3 PENDING),$(pr 4 PENDING)" "$(note 7 comment),$(note 8 mention)"
  run_watch
  local -a sent=(${(f)"$(<$t/notified 2> /dev/null)"})
  (( $#sent == 3 )) ||
    print "a failed check, a new review request and a new note: $#sent notifications, not 3: ${(j: | :)sent}"
  (( ${#${(M)sent:#*'-subtitle o/r#1 -message checks failed: '*}} )) || print "no 'checks failed' for o/r#1"
  (( ${#${(M)sent:#*'-subtitle o/r#4 -message review requested: '*}} )) ||
    print "no 'review requested' for o/r#4"
  (( ${#${(M)sent:#*'-subtitle o/r#8 -message mentioned you: '*}} )) ||
    print "no 'mentioned you' for the new note o/r#8"

  cp $state $t/state.before
  touch $t/gh.fail
  run_watch
  (( $? == 1 )) || print "with gh failing, the run doesn't exit 1"
  [[ -s $t/state/github/error ]] || print "with gh failing, no error is left for check_mac"
  cmp -s $state $t/state.before || print "with gh failing, the state file changed"
  (( ${#${(f)"$(<$t/notified)"}} == 3 )) || print "with gh failing, it notified"
  rm $t/gh.fail
  run_watch
  [[ -e $t/state/github/error ]] && print "after a good run, the error is still there"

  # what the inbox lists from that state: failing checks, then asked of you, then notifications
  out=$(T=$t XDG_STATE_HOME=$t/state PATH=$minimal_path config/github/inbox --list 2>&1)
  local -a kinds=(${${(f)out}%%'|'*})
  [[ ${(j: :)kinds} == "mine asked asked note note" ]] ||
    print -r -- "inbox --list: the order isn't failing, asked, asked, notes: ${(j: :)kinds}"
}

# the hook's state of a Claude Code pane, and the order the agents list and next-agent put them in, in a
# private tmux server pointed at with $TMUX (the scripts call plain `tmux`). @claude-agent and @listed are the
# lines of config/tmux/tmux.conf, so a change to them is tested too.
run_agent_state() {
  (( $+commands[tmux] )) || { print "tmux isn't installed"; return 2 }
  local t=$tmp/state sock=check-agents-$$ real=$commands[tmux] state pane got hidden
  local -a ids order expected
  mkdir -p $t/stubs
  p() { tmux -L $sock "$@" }
  grep -E '^set -g @(claude-agent|listed) ' config/tmux/tmux.conf > $t/tmux.conf
  [[ -s $t/tmux.conf ]] || { print "config/tmux/tmux.conf no longer sets @claude-agent and @listed"; return 1 }
  {
    p -f /dev/null new-session -d -s main 2> $t/err || {
      [[ -n $SANDBOX_RUNTIME ]] && { print "tmux can't make its socket in Claude Code's sandbox"; return 2 }
      print -r -- "couldn't start a tmux server: $(<$t/err)"
      return 1
    }
    p source-file $t/tmux.conf
    p new-session -d -s _hidden
    p split-window -d -t main: && p split-window -d -t main: && p split-window -d -t main:
    ids=(${(f)"$(p list-panes -t main -F '#{pane_id}')"})
    hidden=$(p list-panes -t _hidden -F '#{pane_id}')
    (( $#ids == 4 )) || { print "setup: $#ids panes, not 4"; return 1 }
    export TMUX=$(p display -p '#{socket_path}'),0,0

    for state in working waiting done idle off; do
      TMUX_PANE=$ids[1] config/claude/hooks/tmux-state.sh $state
      got=$(p display -p -t $ids[1] '#{@claude}')
      [[ $got == ${state/off/} ]] || print "tmux-state.sh $state: @claude is '$got'"
    done

    # the order of the lists: waiting, done, working, then idle; a pane in a _ session isn't listed
    p set -p -t $ids[1] @claude idle
    p set -p -t $ids[2] @claude working
    p set -p -t $ids[3] @claude done
    p set -p -t $ids[4] @claude waiting
    p set -p -t $hidden @claude waiting
    order=(${(f)"$(config/tmux/agents --list 2>&1 | cut -f1)"})
    expected=($ids[4] $ids[3] $ids[2] $ids[1])
    [[ $order == $expected ]] ||
      print "agents --list: ${(j: :)order}; should be ${(j: :)expected} (waiting, done, working, idle)"

    # next-agent needs a client: a tmux that logs switch-client and display, and forwards the rest
    print -r -- "#!/bin/sh
case \"\$1\" in switch-client|display) echo \"\$*\" >> $t/calls; exit 0 ;; esac
exec $real -L $sock \"\$@\"" > $t/stubs/tmux
    chmod +x $t/stubs/tmux
    PATH=$t/stubs:$PATH config/tmux/next-agent c $ids[1]
    [[ $(<$t/calls) == "switch-client -c c -t $ids[4]" ]] ||
      print "next-agent from an idle pane: '$(<$t/calls)', should go to the waiting pane $ids[4]"
    : > $t/calls
    PATH=$t/stubs:$PATH config/tmux/next-agent c $ids[4]
    [[ $(<$t/calls) == "switch-client -c c -t $ids[3]" ]] ||
      print "next-agent from the waiting pane: '$(<$t/calls)', should go to the done pane $ids[3]"
    : > $t/calls
    for pane in $ids; do p set -p -t $pane @claude idle; done
    PATH=$t/stubs:$PATH config/tmux/next-agent c $ids[1]
    [[ $(<$t/calls) == "display -c c no agent needs you" ]] ||
      print "next-agent with none waiting or done: '$(<$t/calls)', should say 'no agent needs you'"
  } always {
    tmux_drop $sock
  }
}

# each early run's problems, as a check: the promise is the label below
check_agent_done() { early_result agent_done "7 cases"; }
check_agent_resume() { early_result agent_resume "3 cases"; }
check_agent_land() { early_result agent_land "6 cases"; }
check_github_watch() { early_result github_watch "4 runs and the inbox"; }
check_agent_state() { early_result agent_state "hook, list, next-agent"; }

agent_helpers
early agent_done run_agent_done
early agent_resume run_agent_resume
early agent_land run_agent_land
early github_watch run_github_watch
early agent_state run_agent_state

group "Behaviour: the scripts that run on their own do what they should"
check "zsh starts without errors" check_zsh_start
check "zsh's functions find the repo in Claude Code's shell" check_zsh_exports
check "no-recursive-rm blocks every recursive rm and nothing else" check_rm_hook
check "the format hook formats only where the project asks for it" check_format_hook
check "the bell hook keeps quiet outside tmux" check_bell_hook
check "the status line shows what the session reports" check_statusline
check "new skills are linked into ~/.claude, removed ones unlinked" check_skill_links
check "after a pull, the running programs reload what changed" check_reload
check "agent_done removes a worktree only when nothing would be lost" check_agent_done
check "_agent_worktree brings back what agent_done left" check_agent_resume
check "agent_land lands only a clean, rebased, checked branch" check_agent_land
check "the GitHub watcher notices what changed and nothing else" check_github_watch
check "the agents' state and the order the lists show it in" check_agent_state
