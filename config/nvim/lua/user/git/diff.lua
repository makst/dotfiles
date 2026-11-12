-- This file's diff against a revision, side by side, and closing it: fugitive's :Gvdiffsplit, except for a file
-- the revision doesn't have (new since then), where fugitive prints git's "exists on disk, but not in …":
-- that one gets an empty read-only left side, so the whole file shows as added. Used by user/git/keymaps.lua
-- (,gd / ,gD, against HEAD) and user/git/changes.lua (;g, against the branch's base).
local M = {}

-- has(rev, file) -> whether rev has the file; true outside a git repo, so fugitive reports that itself
local function has(rev, file)
  local dir = vim.fs.dirname(file)
  local function git(...) return vim.system({ 'git', '-C', dir, ... }):wait().code == 0 end
  -- rev:./name is relative to -C's directory, so no path from the repo root is needed
  return git('cat-file', '-e', rev .. ':./' .. vim.fs.basename(file)) or not git('rev-parse', '--is-inside-work-tree')
end

-- open_empty(rev): the file on the right, an empty read-only buffer on the left, both in diff mode. Closing
-- the left side any way (,gD, :q) turns diff mode off on the right.
local function open_empty(rev)
  local win, name = vim.api.nvim_get_current_win(), vim.fn.expand('%:~:.')
  vim.cmd('leftabove vertical new')
  local buf = vim.api.nvim_get_current_buf()
  vim.bo[buf].buftype, vim.bo[buf].bufhidden, vim.bo[buf].swapfile = 'nofile', 'wipe', false
  vim.bo[buf].modifiable = false
  -- close() finds it by this, as nvim makes its name a full path
  vim.b[buf].git_empty_side = true
  pcall(vim.api.nvim_buf_set_name, buf, string.format('not in %s: %s', rev, name))
  vim.cmd('diffthis')
  vim.api.nvim_create_autocmd('BufWipeout', {
    buffer = buf,
    once = true,
    callback = function()
      if vim.api.nvim_win_is_valid(win) then vim.api.nvim_win_call(win, function() vim.cmd('diffoff') end) end
    end,
  })
  vim.api.nvim_set_current_win(win)
  vim.cmd('diffthis')
end

-- open(rev): the diff against rev (default HEAD), the old side on the left; nothing when this window is
-- already in diff mode
function M.open(rev)
  rev = rev or 'HEAD'
  if vim.wo.diff then return end
  local file = vim.api.nvim_buf_get_name(0)
  if file ~= '' and vim.uv.fs_stat(file) and not has(rev, file) then return open_empty(rev) end
  vim.cmd('Gvdiffsplit ' .. vim.fn.fnameescape(rev))
end

-- close(): closes the old side of either kind, in this tab, which turns diff mode off in the file's window
function M.close()
  for _, win in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
    local buf = vim.api.nvim_win_get_buf(win)
    local name = vim.api.nvim_buf_get_name(buf)
    local old = name:match('^fugitive://') or vim.b[buf].git_empty_side
    if old and vim.wo[win].diff and #vim.api.nvim_tabpage_list_wins(0) > 1 then vim.api.nvim_win_close(win, true) end
  end
end

return M
