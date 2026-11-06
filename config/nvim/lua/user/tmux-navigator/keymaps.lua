-- vim-tmux-navigator binds C-h/j/k/l itself (normal and terminal mode); these give them a desc for ;?
local describe = require('user.describe')
describe({ 'n', 't' }, '<C-H>', 'Split: the one to the left, or the tmux pane')
describe({ 'n', 't' }, '<C-J>', 'Split: the one below, or the tmux pane')
describe({ 'n', 't' }, '<C-K>', 'Split: the one above, or the tmux pane')
describe({ 'n', 't' }, '<C-L>', 'Split: the one to the right, or the tmux pane')
describe('n', '<C-Bslash>', 'Split: back to the last one, or the tmux pane')
