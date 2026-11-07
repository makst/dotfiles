-- lualine: the status line, in the colours of the theme. Loaded by config/nvim/init.lua.
local status, lualine = pcall(require, 'lualine')
if (not status) then return end

-- same pieces the old feline line showed
lualine.setup({
  options = {
    theme = 'auto',
    globalstatus = true,
    -- an open picker (fzf-lua's terminal) keeps the line of the file it came from, not the terminal's name,
    -- a term:// path with the whole working directory
    ignore_focus = { 'fzf' },
    -- flat blocks, as the tmux status line: no powerline arrows
    section_separators = '',
    component_separators = '',
  },
  sections = {
    -- bold, as the session name in tmux
    lualine_a = { { 'mode', color = { gui = 'bold' } } },
    lualine_b = { 'branch', 'diff' },
    lualine_c = { { 'filename', path = 1 }, 'diagnostics' },
    lualine_x = { 'lsp_status', 'encoding' },
    lualine_y = { 'progress' },
    lualine_z = { 'location' },
  },
})
