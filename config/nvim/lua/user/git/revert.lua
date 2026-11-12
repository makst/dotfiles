-- ,gr / ,gR: pick a commit and undo it without committing, as fzf-lua's commit pickers with the commit through
-- delta as the preview. ,gr undoes the whole commit (git revert --no-commit, so its changes wait staged for
-- you to read and commit, :Git commit); ,gR picks from this file's commits and undoes only what the commit did
-- to this file, left unstaged. Used by user/git/keymaps.lua.
local status, fzf = pcall(require, 'fzf-lua')
if (not status) then return {} end

local M = {}

local function picker(...) return require('user.fzf-lua.config').picker(...) end

-- sha(selected) -> the picked commit's hash, the first word of its line
local function sha(selected)
  return selected[1] and fzf.utils.strip_ansi_coloring(selected[1]):match('^%s*(%x+)')
end

-- commit(): the repo's commits; the picked one reverted through fugitive, so the open buffers and :Git status
-- show it
function M.commit()
  fzf.git_commits(picker('revert', {
    actions = {
      enter = function(selected)
        local commit = sha(selected)
        if commit then vim.cmd('Git revert --no-commit ' .. commit) end
      end,
    },
  }))
end

-- file(): this file's commits; the picked one's patch for this file, applied in reverse
function M.file()
  local file = vim.api.nvim_buf_get_name(0)
  if file == '' or file:match('^%a+://') then
    return vim.notify('git: open the file whose commit to revert', vim.log.levels.WARN)
  end
  local dir, name = vim.fs.dirname(file), vim.fs.basename(file)
  fzf.git_bcommits(picker('revert in this file', {
    actions = {
      enter = function(selected)
        local commit = sha(selected)
        if not commit then return end
        local patch = vim.system({ 'git', '-C', dir, 'show', '--format=', commit, '--', name }, { text = true }):wait()
        local out = patch.code == 0 and vim.system({ 'git', '-C', dir, 'apply', '-R', '-' },
          { stdin = patch.stdout, text = true }):wait() or patch
        if out.code ~= 0 then
          return vim.notify('git: ' .. vim.trim(out.stderr or ''), vim.log.levels.ERROR)
        end
        vim.cmd('checktime')
      end,
    },
  }))
end

return M
