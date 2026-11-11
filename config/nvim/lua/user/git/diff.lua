-- ,gd / ,gD: this file's diff against HEAD and closing it. git.nvim's diff, except for a file HEAD doesn't
-- have (new on this branch, not committed yet), where git.nvim stops with git's "exists on disk, but not in
-- 'HEAD'": that one gets the same split with an empty left side, so the whole file shows as added.
-- Used by user/git/keymaps.lua.
local M = {}

-- the empty left side, while it's open
local empty_buf

-- in_head(file) -> whether HEAD has the file; true outside a git repo, so git.nvim reports that as before
local function in_head(file)
  local dir = vim.fs.dirname(file)
  local function git(...) return vim.system({ 'git', '-C', dir, ... }):wait().code == 0 end
  -- HEAD:./name is relative to -C's directory, so no path from the repo root is needed
  return git('cat-file', '-e', 'HEAD:./' .. vim.fs.basename(file)) or not git('rev-parse', '--is-inside-work-tree')
end

-- open_empty(): the file on the right, an empty read-only buffer on the left, both in diff mode. Closing the
-- left side any way (,gD, :q) turns diff mode off on the right.
local function open_empty()
  local win, name = vim.api.nvim_get_current_win(), vim.fn.expand('%:~:.')
  vim.cmd('leftabove vertical new')
  local buf = vim.api.nvim_get_current_buf()
  vim.bo[buf].buftype, vim.bo[buf].bufhidden, vim.bo[buf].swapfile = 'nofile', 'wipe', false
  vim.bo[buf].modifiable = false
  pcall(vim.api.nvim_buf_set_name, buf, 'not in HEAD: ' .. name)
  vim.cmd('diffthis')
  vim.api.nvim_create_autocmd('BufWipeout', {
    buffer = buf,
    once = true,
    callback = function()
      empty_buf = nil
      if vim.api.nvim_win_is_valid(win) then vim.api.nvim_win_call(win, function() vim.cmd('diffoff') end) end
    end,
  })
  vim.api.nvim_set_current_win(win)
  vim.cmd('diffthis')
  empty_buf = buf
end

-- open(): the diff against HEAD; nothing when this window is already in diff mode, as git.nvim does
function M.open()
  if vim.wo.diff then return end
  local file = vim.api.nvim_buf_get_name(0)
  if file ~= '' and vim.uv.fs_stat(file) and not in_head(file) then return open_empty() end
  require('git.diff').open()
end

-- close(): closes either kind of diff
function M.close()
  if empty_buf and vim.api.nvim_buf_is_valid(empty_buf) then
    vim.api.nvim_buf_delete(empty_buf, { force = true })
    return
  end
  require('git.diff').close()
end

return M
