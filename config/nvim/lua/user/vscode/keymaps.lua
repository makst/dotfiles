-- VS Code as the visual debugger next to nvim (docs/debugging.md): `,vo` opens this file at this line in VS
-- Code, in the window of the project (the git root, else the working directory), so its debugger finds the
-- project's .vscode/launch.json. Set the breakpoint there and start debugging with F5.
vim.keymap.set('n', '<leader>vo', function()
  if vim.fn.executable('code') == 0 then
    vim.notify('code not found: needs VS Code', vim.log.levels.WARN)
    return
  end
  local root = vim.fs.root(0, '.git') or vim.fn.getcwd()
  local position = ('%s:%d:%d'):format(vim.api.nvim_buf_get_name(0), vim.fn.line('.'), vim.fn.col('.'))
  vim.fn.jobstart({ 'code', root, '--goto', position }, { detach = true })
end, { desc = 'VS Code: open this file at this line, to debug' })
