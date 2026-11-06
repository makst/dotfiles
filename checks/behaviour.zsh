# Behaviour checks: the scripts that run on their own (zsh's start, Claude Code's hooks and status line) do what
# they should. Claude Code's run with only zsh, jq, git and gh on PATH besides the system's own tools, since
# config/claude must work on any machine with just those. Sourced by check_dotfiles.

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

group "Behaviour: the scripts that run on their own do what they should"
check "zsh starts without errors" check_zsh_start
check "no-recursive-rm blocks every recursive rm and nothing else" check_rm_hook
check "the format hook formats only where the project asks for it" check_format_hook
check "the bell hook keeps quiet outside tmux" check_bell_hook
check "the status line shows what the session reports" check_statusline
