local status, _ = pcall(require, 'codetour')
if (not status) then return end
local pickers = require('user.codetour.telescope')
if (not pickers.tours) then return end

-- ;o: pick a tour and open it (:CodeTour open names the same thing)
vim.keymap.set('n', ';o', pickers.tours, { desc = 'Codetour: pick a tour and open it' })

-- ;l: pick a stop of the open tour (:CodeTour list)
vim.keymap.set('n', ';l', pickers.stops, { desc = 'Codetour: pick a stop of the open tour' })
