-- ,go / ,gp / ,gn: this file, this branch's pull request, a new pull request, on GitHub in the browser. gh
-- does it (docs/design.md, "One tool per job": gh owns GitHub), so it works wherever gh is logged in.
-- Used by user/git/keymaps.lua.
local M = {}

-- gh(dir, args…): gh in dir, in the background; what it says on failure shows as a warning
local function gh(dir, ...)
  if vim.fn.executable('gh') == 0 then return vim.notify('git: needs gh', vim.log.levels.WARN) end
  vim.system({ 'gh', ... }, { cwd = dir, text = true }, vim.schedule_wrap(function(out)
    if out.code ~= 0 then vim.notify('gh: ' .. vim.trim(out.stderr or ''), vim.log.levels.WARN) end
  end))
end

-- open(first, last): the file at the line or lines, on this branch when GitHub has it (on the default
-- branch otherwise, where a line may have moved)
function M.open(first, last)
  local file = vim.api.nvim_buf_get_name(0)
  if file == '' or file:match('^%a+://') then return vim.notify('git: this buffer has no file', vim.log.levels.WARN) end
  local dir = vim.fs.dirname(file)
  local lines = (last and last ~= first) and string.format('%d-%d', first, last) or tostring(first)
  local args = { 'browse', vim.fs.basename(file) .. ':' .. lines }
  local branch = vim.trim(vim.system({ 'git', '-C', dir, 'branch', '--show-current' }, { text = true }):wait().stdout or '')
  local pushed = branch ~= '' and
    vim.system({ 'git', '-C', dir, 'rev-parse', '--verify', '--quiet', 'refs/remotes/origin/' .. branch }):wait().code == 0
  if pushed then vim.list_extend(args, { '--branch', branch }) end
  gh(dir, unpack(args))
end

-- pull_request(): this branch's pull request
function M.pull_request() gh(vim.fn.getcwd(), 'pr', 'view', '--web') end

-- new_pull_request(): GitHub's page for a pull request from this branch (push it first)
function M.new_pull_request() gh(vim.fn.getcwd(), 'pr', 'create', '--web') end

return M
