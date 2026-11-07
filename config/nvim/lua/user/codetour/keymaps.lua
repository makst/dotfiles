-- Codetour's ;o and ;l, and the fzf keys inside its pickers. Loaded by user/codetour/init.lua; picker_keys
-- is read by user/codetour/picker.
local status, _ = pcall(require, 'codetour')
if (not status) then return {} end

local M = {}

-- inside the pickers (user/codetour/picker), as fzf keys. remove: delete the tour (;o, asks first) / remove
-- the stop (;l); reword: the stop's note (;l). normal: in normal mode d and r press them too (picker_modes);
-- fzf has no two-key sequences, so d, not dd.
M.picker_keys = {
  remove = 'alt-d',
  reword = 'alt-r',
  normal = 'd:alt-d,r:alt-r',
}

-- ;o: pick a tour and open it (:CodeTour open names the same thing)
vim.keymap.set('n', ';o', function() require('user.codetour.picker').tours() end,
  { desc = 'Codetour: pick a tour and open it' })

-- ;l: pick a stop of the open tour (:CodeTour list)
vim.keymap.set('n', ';l', function() require('user.codetour.picker').stops() end,
  { desc = 'Codetour: pick a stop of the open tour' })

return M
