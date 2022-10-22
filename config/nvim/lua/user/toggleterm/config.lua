---@diagnostic disable: lowercase-global
local status, toggleterm = pcall(require, "toggleterm")
if (not status) then return end

toggleterm.setup {}

local Terminal = require('toggleterm.terminal').Terminal

local lazygit = Terminal:new({
  cmd = "lazygit",
  hidden = true,
  direction = "float",
  float_opts = {
    border = "double",
  },
})

local testterm = Terminal:new({
  hidden = true,
  direction = "float",
  float_opts = {
    border = "double",
  },
})

local miscterm = Terminal:new({
  hidden = true,
  direction = "float",
  float_opts = {
    border = "double",
  },
})

function _lazygit_toggle()
  lazygit:toggle()
end

function _testterm_toggle()
  testterm:toggle()
end

function _miscterm_toggle()
  miscterm:toggle()
end
