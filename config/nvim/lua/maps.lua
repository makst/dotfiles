vim.g.mapleader = ','
local keymap = vim.keymap

keymap.set('i', 'jj', '<Esc>')

-- Do not yank with x
keymap.set('n', 'x', '"_x')

-- Quit/Save file
keymap.set('n', '<leader>q', ':q!<Return>')
keymap.set('n', '<leader>w', ':w!<Return>')

-- Buffers
keymap.set('n', 'bn', ':bn<Return>')
keymap.set('n', 'bp', ':bp<Return>')
keymap.set('n', 'bb', ':b#<Return>')
keymap.set('n', 'bd', ':bd<Return>')
keymap.set('n', 'bls', ':ls<Return>')
-- https://stackoverflow.com/a/42071865
-- %bd = delete all buffers, e# = open the last buffer for editing, bd# to delete the [No Name] buffer that gets created.
-- The pipe in between does one command after another.
keymap.set('n', 'bdr', ':%bd|e#|bd#<Return>')

-- Split window
keymap.set('n', 'ss', ':split<Return><C-w>w')
keymap.set('n', 'sv', ':vsplit<Return><C-w>w')

-- Move window
keymap.set('n', '<Space>', '<C-w>w')
keymap.set('', 'sh', '<C-w>h')
keymap.set('', 'sk', '<C-w>k')
keymap.set('', 'sj', '<C-w>j')
keymap.set('', 'sl', '<C-w>l')

-- Resize window
keymap.set('n', '<left>', '<C-w><')
keymap.set('n', '<right>', '<C-w>>')
keymap.set('n', '<up>', '<C-w>+')
keymap.set('n', '<down>', '<C-w>-')
