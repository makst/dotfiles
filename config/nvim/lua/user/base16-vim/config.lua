-- base16-vim (tinted-vim): the colour scheme, following macOS light and dark mode like Ghostty does
-- (docs/theme.md). Loaded by lua/user/base16-vim/init.lua.
--
-- nvim works out 'background' itself from the terminal's background colour: it asks when it starts, and asks
-- again whenever the terminal reports a theme change (DEC mode 2031; Ghostty sends it when macOS switches,
-- tmux passes it on). Each time 'background' changes, the scheme for it from schemes.lua is loaded. Nothing
-- here sets 'background', since setting it by hand would turn nvim's own detection off. Starting in light
-- mode can show the dark scheme for a moment, until the terminal's answer comes in.
local schemes = require('user.base16-vim.schemes')

local function load_scheme()
  local scheme = schemes[vim.o.background]
  if scheme and vim.g.colors_name ~= scheme then vim.cmd.colorscheme(scheme) end
end

load_scheme()
-- OptionSet doesn't fire before VimEnter, and the terminal's answer can come in by then
vim.api.nvim_create_autocmd('VimEnter', {
  once = true,
  desc = "Theme: load the colour scheme for 'background' as nvim worked it out while starting",
  callback = load_scheme,
})
vim.api.nvim_create_autocmd('OptionSet', {
  pattern = 'background',
  desc = "Theme: load the colour scheme for the new 'background' (macOS switched light/dark)",
  callback = load_scheme,
})
