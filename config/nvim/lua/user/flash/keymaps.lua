local status, flash = pcall(require, 'flash')
if (not status) then return end

-- m: type a few characters of where you want to go, then the label shown there
vim.keymap.set({ 'n', 'x', 'o' }, 'm', function() flash.jump() end)
