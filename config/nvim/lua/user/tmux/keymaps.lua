-- tmux from nvim (config.lua): lazygit in a popup, and two shells per working directory in a pane below. zsh's
-- normal mode has the same keys (.fzf.zsh), so the key that shows a shell hides it again from inside.
local tmux = require('user.tmux.config')

vim.keymap.set('n', '<leader>lg', tmux.lazygit, { desc = 'Terminal: lazygit in a tmux popup' })
vim.keymap.set('n', '<leader>tt', function() tmux.scratch('tt') end, { desc = 'Terminal: the test shell, shown or hidden' })
vim.keymap.set('n', '<leader>tm', function() tmux.scratch('tm') end, { desc = 'Terminal: the spare shell, shown or hidden' })
