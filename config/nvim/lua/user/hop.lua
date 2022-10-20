local status, hop = pcall(require, 'hop')
if (not status) then return end

hop.setup {}

vim.keymap.set('', 'm', function()
  hop.hint_words()
end, {remap=true})
