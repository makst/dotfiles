GIFs
===

The animations in these docs show what a key does. They're recorded from scripts, not by hand, so they can
be made again whenever a binding or the colour scheme changes.

![tmux panes](img/tmux-panes.gif)

How they're made
---
- Each GIF has a [VHS](https://github.com/charmbracelet/vhs) tape in `docs/tapes/<name>.tape`: the keys to
  press and how long to wait, e.g. `Ctrl+a Type "|" Sleep 1.2s`. The GIF goes to `docs/img/<name>.gif`.
- `make_gifs` (`zsh/.functions`) renders them: all tapes, or the ones named (`make_gifs tmux-panes`). It
  adds the Ghostty font and colour scheme to each tape, so the GIFs match the terminal and follow
  `change_theme`.
- The recording runs the real tmux config in a separate tmux server (`tmux -L demo`, with
  `docs/tapes/demo.tmux.conf`) and a throwaway `HOME` that has only tpm and vim-tmux-navigator. Your sessions
  aren't touched: resurrect and continuum don't load, so they neither restore nor save. Shells inside get the
  real `HOME` back, so the prompt and aliases look as usual, minus the AWS profile.
- `docs/tapes/keycast` sits between the terminal and tmux and shows each key pressed as a yellow badge on a
  second status line. A prefix chord that a Ghostty `cmd` key sends shows as that key, the one you'd press:
  the tape types `C-a |`, the badge says `cmd+d`. It reads the keybinds from `config/ghostty/config`, so it
  stays right when they change. Chords without a Ghostty key show as `C-a l`, keys without prefix as `C-h`.
  Plain typing shows no badge, since the text appears in the pane anyway. It's Python because it needs a
  pseudo-terminal in the middle of the input.
- VHS can't press `cmd` (it records a terminal in a browser, not Ghostty), so tapes type the tmux keys
  Ghostty would send: `Ctrl+a Type "|"` for `cmd+d`. A comment above each says which `cmd` key it is.

Adding one
---
1. Write `docs/tapes/<name>.tape`, starting with `Output docs/img/<name>.gif`. The tape starts inside tmux,
   in the repo, in the session `main`. See the [VHS commands](https://github.com/charmbracelet/vhs#vhs-command-reference).
2. `make_gifs <name>` and look at the result.
3. Embed it next to the keys it shows: `![what it shows](img/<name>.gif)`.

Keep them short (around 15 s) and under ~1 MB, since every version stays in git.

Needs `vhs` (which brings `ttyd` and `ffmpeg`) and the Symbols Nerd Font for the icons, both in the Brewfile.
