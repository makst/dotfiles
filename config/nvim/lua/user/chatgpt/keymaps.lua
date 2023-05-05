local M = {}

M.edit_with_instructions = {
  accept = "<C-y>",
  toggle_diff = "<C-d>",
  toggle_settings = "<C-o>",
  cycle_windows = "<Tab>",
  use_output_as_input = "<C-i>"
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

return M;
