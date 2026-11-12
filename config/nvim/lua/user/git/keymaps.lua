-- The git keys: ,g… act on this file or repo through fugitive (status, blame, diff) and gh (the GitHub pages);
-- ;g lists the branch's changed files. Loaded by user/git/init.lua; the work is in user/git/diff, changes,
-- revert and github. Inside fugitive's own buffers (status, blame), g? lists their keys.
local function map(mode, lhs, rhs, desc)
  vim.keymap.set(mode, lhs, rhs, { silent = true, desc = desc })
end

-- fugitive's status in a split: s / u stage and unstage the file or the lines selected, = shows its diff
-- inline, cc commits, dv opens the diff side by side (shell: gs)
map('n', '<leader>gs', '<Cmd>Git<CR>', 'Git: status, to stage and commit')
map('n', '<leader>gb', '<Cmd>Git blame<CR>', 'Git: blame for this file')
map('n', '<leader>go', function() require('user.git.github').open(vim.fn.line('.')) end,
  'Git: open this file on GitHub')
map('x', '<leader>go', function()
  local first, last = vim.fn.line('v'), vim.fn.line('.')
  vim.api.nvim_feedkeys(vim.keycode('<Esc>'), 'nx', false)
  require('user.git.github').open(math.min(first, last), math.max(first, last))
end, 'Git: open these lines on GitHub')
map('n', '<leader>gp', function() require('user.git.github').pull_request() end, "Git: open this branch's pull request")
map('n', '<leader>gn', function() require('user.git.github').new_pull_request() end, 'Git: create a pull request')
-- through user/git/diff, which also diffs a file HEAD doesn't have, against an empty side
map('n', '<leader>gd', function() require('user.git.diff').open() end, 'Git: diff this file against HEAD')
map('n', '<leader>gD', function() require('user.git.diff').close() end, 'Git: close the diff')
map('n', '<leader>gr', function() require('user.git.revert').commit() end, 'Git: pick a commit to revert')
map('n', '<leader>gR', function() require('user.git.revert').file() end, 'Git: pick a commit of this file to revert')

-- ;g: the changed files since the branch left the default branch, to review (shell: ;g too)
vim.keymap.set('n', ';g', function() require('user.git.changes').pick() end,
  { desc = 'Git: changed files of this branch, to review' })
