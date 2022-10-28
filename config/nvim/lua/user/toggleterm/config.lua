---@diagnostic disable: lowercase-global
local status, toggleterm = pcall(require, 'toggleterm')
if (not status) then return end

toggleterm.setup {}

local lg_terminal_map = {}
local test_terminal_map = {}
local misc_terminal_map = {}

local Terminal = require('toggleterm.terminal').Terminal

function _lazygit_toggle()
  local cwd = vim.fn.getcwd()
  if (lg_terminal_map[cwd] == nil) then
    lg_terminal_map[cwd] = Terminal:new({
      cmd = 'lazygit',
      autochdir = true,
      hidden = true,
      direction = 'float',
      float_opts = {
        border = 'double',
      },
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
        border = 'double',
      },
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
        border = 'double',
      },
    })
  end

  misc_terminal_map[cwd]:toggle()
end
