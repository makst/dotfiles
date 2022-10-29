local util = require('user.ferret.util')

vim.keymap.set('v', '<leader>av', function()
  vim.cmd(':Ack --fixed-strings ' .. util.get_searchable_visual_selection())
end)
