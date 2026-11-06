local status, git = pcall(require, 'git')
if (not status) then return end

-- its own keys off: keymaps.lua binds the same ones, with a desc each so they show in the keys picker (;?)
git.setup({ default_mappings = false })
