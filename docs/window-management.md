Window management (yabai + skhd)
===

[yabai](https://github.com/koekeishiya/yabai) tiles macOS windows automatically;
[skhd](https://github.com/koekeishiya/skhd) gives it keyboard shortcuts. Both are installed by the Brewfile
but are **opt-in**: `setup_dotfiles` doesn't start them.

Config: `config/.yabairc`, `config/.skhdrc` (linked to `~/.yabairc` and `~/.skhdrc`).

Enabling
---
1. Decide about SIP (below).
2. Run `setup_window_management`: links the configs and starts both as launch agents.
3. Give yabai and skhd Accessibility access (System Settings → Privacy & Security → Accessibility), then
   run it again.

`yabai --stop-service` / `skhd --stop-service` turn them off again.

**SIP.** yabai's scripting addition needs System Integrity Protection partly disabled (on Apple silicon also
a boot argument), see the [yabai wiki](https://github.com/koekeishiya/yabai/wiki/Disabling-System-Integrity-Protection).
This setup leaves SIP on and doesn't load it. Tiling, focus, swapping, resizing and moving windows between
displays work without it. Creating spaces, moving windows between spaces, and focusing spaces generally
don't.

Layout
---
Every space is a binary split layout (bsp): each new window splits the focused one, with 10 px gaps and
padding. System Settings and Archive Utility float.

Hold `fn` and drag with the mouse to move a window (drop it on another to swap them), or right-drag to
resize.

Keys
---
All on `Option` (Alt). skhd captures these system-wide, so while it runs they don't reach other apps:
Alt+h/j/k/l in nvim or zsh, for instance, are handled by yabai.

| Key | Action |
|---|---|
| `alt+h/j/k/l` | focus the window left/down/up/right |
| `shift+alt+h/j/k/l` | swap with the window in that direction |
| `ctrl+shift+alt+h/j/k/l` | move the window to that side of the layout |
| `alt+r` | rotate the layout 90° |
| `alt+e` | switch the split between horizontal and vertical |
| `shift+alt+0` | make all windows equal size |
| `alt+f` | zoom the window to fill the space (toggle) |
| `alt+t` | float the window, centred (toggle) |
| `alt+g` | toggle gaps and padding |
| `shift+alt+1`…`9` | move the window to space 1…9 and follow it (needs the scripting addition) |
| `shift+alt+c` | create a space, move the window there and follow it (needs the scripting addition) |
| `alt+0` | back to the previous space (needs the scripting addition) |
| `shift+alt+n` / `shift+alt+p` | move the window to the next / previous display and follow it |
