local status_dap, _ = pcall(require, "dap")
if not status_dap then return end

local icons_module = require("user.debug.dap.icons")

vim.highlight.create('DapBreakpoint', { ctermbg = 0, guifg = '#993939', guibg = '#31353f' }, false)
vim.highlight.create('DapLogPoint', { ctermbg = 0, guifg = '#61afef', guibg = '#31353f' }, false)
vim.highlight.create('DapStopped', { ctermbg = 0, guifg = '#98c379', guibg = '#31353f' }, false)

vim.fn.sign_define('DapBreakpoint',
  { text = icons_module.icons.DapBreakpoint, texthl = 'DapBreakpoint', linehl = 'DapBreakpoint',
    numhl = 'DapBreakpoint' })
vim.fn.sign_define('DapBreakpointCondition',
  { text = icons_module.icons.DapBreakpointCondition, texthl = 'DapBreakpoint', linehl = 'DapBreakpoint',
    numhl = 'DapBreakpoint' })
vim.fn.sign_define('DapBreakpointRejected',
  { text = icons_module.icons.DapBreakpointRejected, texthl = 'DapBreakpoint', linehl = 'DapBreakpoint',
    numhl = 'DapBreakpoint' })
vim.fn.sign_define('DapLogPoint',
  { text = icons_module.icons.DapLogPoint, texthl = 'DapLogPoint', linehl = 'DapLogPoint', numhl = 'DapLogPoint' })
vim.fn.sign_define('DapStopped',
  { text = icons_module.icons.DapStopped, texthl = 'DapStopped', linehl = 'DapStopped', numhl = 'DapStopped' })
