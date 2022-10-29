local M = {}

local function get_visual_selection()
  -- Yank current visual selection into the 'v' register
  -- Note that this makes no effort to preserve this register
  vim.cmd('noau normal! "vy"')
  return vim.fn.getreg('v')
end

M.get_searchable_visual_selection = function()
  local vs = get_visual_selection()
  -- substitue ' ' with '/ '
  return string.gsub(vs, ' ', '\\ ')
end

return M
