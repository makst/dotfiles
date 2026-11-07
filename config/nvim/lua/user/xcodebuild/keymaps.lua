-- xcodebuild.nvim's keys (,i…): build, run, test, pick a scheme or device. Loaded by xcodebuild/init.lua.
local status_ok, _ = pcall(require, 'xcodebuild')
if not status_ok then return end

local map = function(lhs, rhs, desc)
  vim.keymap.set('n', lhs, rhs, { desc = desc })
end

map('<leader>ip', '<cmd>XcodebuildPicker<cr>', 'Xcode: all actions')
map('<leader>iS', '<cmd>XcodebuildSetup<cr>', 'Xcode: set up this project')
map('<leader>ib', '<cmd>XcodebuildBuild<cr>', 'Xcode: build')
map('<leader>ir', '<cmd>XcodebuildBuildRun<cr>', 'Xcode: build and run')
map('<leader>ix', '<cmd>XcodebuildCancel<cr>', 'Xcode: cancel the running build or test')
map('<leader>it', '<cmd>XcodebuildTest<cr>', 'Xcode: run the tests')
map('<leader>if', '<cmd>XcodebuildTestClass<cr>', 'Xcode: run the tests in this class')
map('<leader>is', '<cmd>XcodebuildSelectScheme<cr>', 'Xcode: pick the scheme')
map('<leader>id', '<cmd>XcodebuildSelectDevice<cr>', 'Xcode: pick the simulator or device')
map('<leader>il', '<cmd>XcodebuildToggleLogs<cr>', 'Xcode: show / hide the build log')

-- The same file and line in Xcode, for what only Xcode does: previews, the visual debugger, signing.
-- xed opens it in the Xcode window that already has the project.
map('<leader>io', function()
  if vim.fn.executable('xed') == 0 then
    vim.notify('xed not found: needs Xcode', vim.log.levels.WARN)
    return
  end
  vim.fn.jobstart({ 'xed', '--line', tostring(vim.fn.line('.')), vim.api.nvim_buf_get_name(0) })
end, 'Xcode: open this file at this line')
