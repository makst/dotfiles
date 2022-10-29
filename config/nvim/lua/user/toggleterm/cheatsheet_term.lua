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

function M.open_term(cmd, opts)
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

local lang = ''
local function cht_on_open(term)
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

function M.cht()
  lang = ''
  vim.ui.input({ prompt = 'cht.sh input: ' }, function(input)
    local cmd = ''
    if input == '' or not input then
      return
    elseif input == 'h' then
      cmd = ''
    else
      local search = ''
      local delimiter = ' '
      for w in (input .. delimiter):gmatch('(.-)' .. delimiter) do
        if lang == '' then
          lang = w
        else
          if search == '' then
            search = w
          else
            search = search .. '+' .. w
          end
        end
      end
      cmd = lang
      if search ~= '' then
        cmd = cmd .. '/' .. search
      end
    end
    cmd = 'curl cht.sh/' .. cmd
    M.open_term(cmd, { on_open = cht_on_open, on_exit = cht_on_exit })
  end)
end

return M
