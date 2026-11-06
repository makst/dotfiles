---@diagnostic disable: lowercase-global
local status, toggleterm = pcall(require, 'toggleterm')
if (not status) then return end

toggleterm.setup {}

local lg_terminal_map = {}
local test_terminal_map = {}
local misc_terminal_map = {}

local Terminal = require('toggleterm.terminal').Terminal

-- the toggle keys also work inside these floats, so the same key hides them again; local to their buffers, so
-- other terminals (Gradle, logcat) don't hold every `,` waiting for a second key
local function map_toggles(term)
  local opts = { buffer = term.bufnr, silent = true }
  vim.keymap.set('t', '<leader>lg', _lazygit_toggle, opts)
  vim.keymap.set('t', '<leader>tt', _testterm_toggle, opts)
  vim.keymap.set('t', '<leader>tm', _miscterm_toggle, opts)
end

function _lazygit_toggle()
  local cwd = vim.fn.getcwd()
  if (lg_terminal_map[cwd] == nil) then
    lg_terminal_map[cwd] = Terminal:new({
      cmd = 'lazygit',
      autochdir = true,
      hidden = true,
      direction = 'float',
      float_opts = {
        border = 'rounded',
      },
      on_open = map_toggles,
    })
  end

  lg_terminal_map[cwd]:toggle()
end

function _testterm_toggle()
  local cwd = vim.fn.getcwd()
  if (test_terminal_map[cwd] == nil) then
    test_terminal_map[cwd] = Terminal:new({
      hidden = true,
      direction = 'float',
      float_opts = {
        border = 'rounded',
      },
      on_open = map_toggles,
    })
  end

  test_terminal_map[cwd]:toggle()
end

function _miscterm_toggle()
  local cwd = vim.fn.getcwd()
  if (misc_terminal_map[cwd] == nil) then
    misc_terminal_map[cwd] = Terminal:new({
      hidden = true,
      direction = 'float',
      float_opts = {
        border = 'rounded',
      },
      on_open = map_toggles,
    })
  end

  misc_terminal_map[cwd]:toggle()
end
