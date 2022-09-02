local status, autopairs = pcall(require, "onedark")
if (not status) then return end

require('onedark').setup {
    style = 'darker'
}
require('onedark').load()
