local status, _ = pcall(require, 'git')
if (not status) then return end

-- git.nvim's own keys, bound here with a desc (config.lua turns its defaults off)
local function map(mode, lhs, rhs, desc)
  vim.keymap.set(mode, lhs, rhs, { silent = true, desc = desc })
end

map('n', '<leader>gb', function() require('git.blame').blame() end, 'Git: blame for this file')
map('n', '<leader>go', function() require('git.browse').open(false) end, 'Git: open this file on the git host')
map('x', '<leader>go', ':<C-u>lua require("git.browse").open(true)<CR>', 'Git: open these lines on the git host')
map('n', '<leader>gp', function() require('git.browse').pull_request() end, "Git: open this branch's pull request")
map('n', '<leader>gn', function() require('git.browse').create_pull_request() end, 'Git: create a pull request')
map('n', '<leader>gd', function() require('git.diff').open() end, 'Git: diff this file against HEAD')
map('n', '<leader>gD', function() require('git.diff').close() end, 'Git: close the diff')
map('n', '<leader>gr', function() require('git.revert').open(false) end, 'Git: pick a commit to revert')
map('n', '<leader>gR', function() require('git.revert').open(true) end, 'Git: pick a commit of this file to revert')
