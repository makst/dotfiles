local status, codetour = pcall(require, 'codetour')
if (not status) then return end

-- Tours live in <git root>/.codetour by default; a folder's .nvim.lua can point storage_path elsewhere.
-- Open tours with :CodeTour open, so starting nvim never pulls you into the last one.
codetour.setup({ auto_open_last_tour = false })
