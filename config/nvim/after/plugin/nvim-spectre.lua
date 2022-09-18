local status, spectre = pcall(require, "spectre")
if (not status) then return end

spectre.setup {}

vim.keymap.set('n', '<leader>S',
  function()
    spectre.open()
  end)
vim.keymap.set('n', '<leader>sw',
  function()
    spectre.open_visual({
      select_word = true
    })
  end)
vim.keymap.set('n', '<leader>sp',
  function ()
    spectre.open_file_search()
  end)
