local status, lualine = pcall(require, 'lualine')
if (not status) then return end

-- same pieces the old feline line showed
lualine.setup({
  options = {
    theme = 'auto',
    globalstatus = true,
  },
  sections = {
    lualine_a = { 'mode' },
    lualine_b = { 'branch', 'diff' },
    lualine_c = { { 'filename', path = 1 }, 'diagnostics' },
    lualine_x = { 'lsp_status', 'encoding' },
    lualine_y = { 'progress' },
    lualine_z = { 'location' },
  },
})
