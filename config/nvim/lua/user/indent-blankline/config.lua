local status, ibl = pcall(require, 'ibl')
if (not status) then return end

-- indent-blankline v3: module `ibl`; the v2 "current context" options became `scope`
ibl.setup {
  scope = {
    enabled = true,
    show_start = true,
  },
}
