Theme
===

One [base16](https://github.com/tinted-theming/home) colour scheme drives everything, so the editor,
terminal, prompt and tools always match. The current scheme is `base16-onedark`.

How it propagates
---
Only two things know the actual colours; everything else uses the terminal's 16 ANSI colours and follows
along:

| Uses the scheme directly | Uses the 16 terminal colours |
|---|---|
| nvim (`tinted-vim` colour schemes) | tmux status bar, starship prompt, fzf, bat, lazygit |
| Ghostty (`config/ghostty/themes/base16`, generated) | file colours in eza, fzf-tab and completion (vivid's `ansi` theme) |

Switching schemes
---
```sh
change_theme
```

Pick a scheme in fzf (every base16 scheme tinted-vim ships, a few hundred). It writes the nvim colour scheme
file and regenerates Ghostty's theme from the same colours, using the standard base16 → ANSI mapping.
Then reload Ghostty (`cmd+shift+,`) and restart nvim. Both files are in the repo, so commit them to keep the
scheme.

It needs nvim's plugins installed, because the scheme list comes from tinted-vim.

Fonts and icons
---
Text is Source Code Pro. Icons in eza, starship, nvim and the tmux status bar are Nerd Font glyphs, which
Ghostty draws from its built-in symbol font, so the text font needn't be a patched Nerd Font. Hack Nerd Font
is installed as well.
