local status_dap, dap = pcall(require, "dap")
if not status_dap then return end

dap.adapters.node2 = {
  type = 'executable',
  command = 'node',
  args = { os.getenv('HOME') .. '/.local/share/nvim/mason/packages/node-debug2-adapter/out/src/nodeDebug.js' },
}

dap.configurations.javascript = {
  {
    -- For this to work you need to make sure the node process is started with the `--inspect` flag.
    name = 'Attach to process',
    type = 'node2',
    request = 'attach',
    processId = require 'dap.utils'.pick_process,
  },
}

dap.configurations.typescript = {
  {
    -- For this to work you need to make sure the node process is started with the `--inspect` flag.
    name = 'Attach to process',
    type = 'node2',
    request = 'attach',
    processId = require 'dap.utils'.pick_process,
  },
}
