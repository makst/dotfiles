local status, codetour = pcall(require, 'codetour')
if (not status) then return end

-- Tours live in <git root>/.codetour by default; a folder's .nvim.lua can point storage_path elsewhere.
-- Open tours with :CodeTour open, so starting nvim never pulls you into the last one.
-- the notes as blocks above their lines (user/codetour/notes), set before setup draws them
require('user.codetour.notes').setup()
codetour.setup({ auto_open_last_tour = false })

-- :CodeTour open (with no name and none to reopen) and :CodeTour list use the fzf-lua pickers
-- (user/codetour/picker)
local pickers = require('user.codetour.picker')
if pickers.tours then
  local plugin_pickers = require('codetour.picker')
  plugin_pickers.tours = pickers.tours
  plugin_pickers.stops = pickers.stops
end
