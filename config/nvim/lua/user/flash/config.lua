local status, flash = pcall(require, 'flash')
if (not status) then return end

flash.setup({
  modes = {
    -- leave f/F/t/T alone: flash would also take over ; and , to repeat them, and those are the picker
    -- prefix and the leader
    char = { enabled = false },
  },
})
