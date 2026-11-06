-- fzf-lua's socket, required from init.lua before any plugin loads fzf-lua (codetour, xcodebuild, user.fzf-lua).
-- fzf-lua talks to nvim through a socket of its own and fails to load without one. Where a unix socket can't be
-- made (Claude Code's sandbox, so headless nvim in checks), a port on localhost does the same.
if not vim.g.fzf_lua_server then
  local ok, server = pcall(vim.fn.serverstart, 'fzf-lua.' .. os.time())
  if not ok then ok, server = pcall(vim.fn.serverstart, '127.0.0.1:0') end
  if ok then vim.g.fzf_lua_server = server end
end
