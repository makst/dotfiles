local M = {}

M.edit_with_instructions = {
  accept = "<C-s>",
  toggle_diff = "<C-d>",
  toggle_settings = "<C-o>",
  cycle_windows = "<Tab>",
  use_output_as_input = "<C-k>"
}

M.chat = {
  close = { "<C-c>" },
  yank_last = "<C-y>",
  yank_last_code = "<C-k>",
  scroll_up = "<C-u>",
  scroll_down = "<C-d>",
  toggle_settings = "<C-o>",
  new_session = "<C-n>",
  cycle_windows = "<Tab>",
  select_session = "<Space>",
  rename_session = "r",
  delete_session = "d"
}

local opts = { noremap = true, silent = true }
vim.api.nvim_set_keymap('n', '<leader>g', ':lua require("chatgpt").openChat()<CR>', opts)
vim.api.nvim_set_keymap('n', '<leader>ga', ':lua require("chatgpt").selectAwesomePrompt()<CR>', opts)
vim.api.nvim_set_keymap('n', '<leader>gei', ':lua require("chatgpt").edit_with_instructions()<CR>', opts)

return M;
