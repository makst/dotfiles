local status, symbols_outline = pcall(require, 'symbols-outline')
if (not status) then return end

symbols_outline.setup {}
