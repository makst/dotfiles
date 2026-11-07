-- harpoon's setup (a short list of marked files). Loaded by user/harpoon/init.lua.
local status_ok, harpoon = pcall(require, 'harpoon')
if not status_ok then
  return
end
harpoon:setup()
