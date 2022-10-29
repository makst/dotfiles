local status, _ = pcall(require, 'toggleterm')
if (not status) then return end

local Terminal = require('toggleterm.terminal').Terminal

------------------ Cheatsheet ----------------------------
--- source: https://github.com/alpha2phi/neovim-for-beginner/blob/55-3rd-party-tools/lua/utils/term.lua#L94-L164
local M = {}

-- Open a terminal
local function default_on_open(term)
  vim.cmd 'stopinsert'
  vim.api.nvim_buf_set_keymap(term.bufnr, 'n', 'q', '<cmd>close<CR>', { noremap = true, silent = true })
end

local function open_term(cmd, opts)
  opts.size = opts.size or vim.o.columns * 0.5
  opts.direction = opts.direction or 'vertical'
  opts.on_open = opts.on_open or default_on_open
  opts.on_exit = opts.on_exit or nil

  local new_term = Terminal:new {
    cmd = cmd,
    dir = 'git_dir',
    auto_scroll = false,
    close_on_exit = false,
    start_in_insert = false,
    on_open = opts.on_open,
    on_exit = opts.on_exit,
  }
  new_term:open(opts.size, opts.direction)
end

local function cht_on_open(term)
  local lang = ''
  vim.cmd 'stopinsert'
  vim.api.nvim_buf_set_keymap(term.bufnr, 'n', 'q', '<cmd>close<CR>', { noremap = true, silent = true })
  vim.api.nvim_buf_set_name(term.bufnr, 'cheatsheet-' .. term.bufnr)
  vim.api.nvim_buf_set_option(term.bufnr, 'filetype', 'cheat')
  vim.api.nvim_buf_set_option(term.bufnr, 'syntax', lang)
end

---@diagnostic disable-next-line: unused-local
local function cht_on_exit(term)
  vim.cmd [[normal gg]]
end

function M.open(full_path)
  local cmd = 'cat ' .. full_path
  open_term(cmd, { on_open = cht_on_open, on_exit = cht_on_exit })
end

return M
