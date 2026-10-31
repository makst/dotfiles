local status, oil = pcall(require, 'oil')
if (not status) then return end

-- -: the current file's directory in oil; in oil, - goes up another level
vim.keymap.set('n', '-', oil.open, { desc = 'Open parent directory' })
