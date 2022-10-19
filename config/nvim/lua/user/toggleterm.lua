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

function _lazygit_toggle()
  lazygit:toggle()
end

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

function _testterm_toggle()
  testterm:toggle()
end

function _miscterm_toggle()
  miscterm:toggle()
end

vim.api.nvim_set_keymap("n", "<leader>lg", "<cmd>lua _lazygit_toggle()<CR>", { noremap = true, silent = true })
vim.api.nvim_set_keymap("t", "<leader>lg", "<cmd>lua _lazygit_toggle()<CR>", { noremap = true, silent = true })
vim.api.nvim_set_keymap("n", "<leader>tt", "<cmd>lua _testterm_toggle()<CR>", { noremap = true, silent = true })
vim.api.nvim_set_keymap("t", "<leader>tt", "<cmd>lua _testterm_toggle()<CR>", { noremap = true, silent = true })
vim.api.nvim_set_keymap("n", "<leader>tm", "<cmd>lua _miscterm_toggle()<CR>", { noremap = true, silent = true })
vim.api.nvim_set_keymap("t", "<leader>tm", "<cmd>lua _miscterm_toggle()<CR>", { noremap = true, silent = true })
