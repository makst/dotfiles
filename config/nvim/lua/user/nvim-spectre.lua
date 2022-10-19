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
-- search a word under cursor in the current file
vim.keymap.set('n', '<leader>sp',
  function()
    vim.cmd('normal viwy')
    spectre.open_file_search()
    vim.cmd('normal p')
  end)
