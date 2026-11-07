-- The jobs nvim hands to tmux (docs/design.md, "One tool per job"), at nvim's working directory: two shells that
-- keep running in a tmux pane below nvim, and lazygit in a tmux popup over it. keymaps.lua binds them; outside
-- tmux they only say so.
local M = {}

local function in_tmux()
  if vim.env.TMUX then return true end
  vim.notify('needs tmux', vim.log.levels.WARN)
end

-- scratch(name): the shell `name` for the working directory, shown below nvim or hidden (config/tmux/scratch)
function M.scratch(name)
  if not in_tmux() then return end
  vim.system({ vim.fn.expand('~/.config/tmux/scratch'), name, vim.fn.getcwd() })
end

-- lazygit's settings for a lazygit started from here: a file opened in it goes to this nvim
local lazygit_config = vim.fs.joinpath(vim.fs.dirname(vim.fn.resolve(vim.fn.stdpath('config'))), 'lazygit', 'nvim.yml')

-- lazygit(): lazygit for the working directory, placed like the tmux pickers (@popup-x, config/tmux/tmux.conf);
-- it draws its own boxes, so the popup has no border. NVIM tells it this nvim's server (config/lazygit/nvim.yml)
function M.lazygit()
  if not in_tmux() then return end
  vim.system({ 'tmux', 'display-popup', '-E', '-B', '-x', '#{E:@popup-x}', '-y', '#{E:@popup-y}', '-w', '80%',
    '-h', '80%', '-d', vim.fn.getcwd(), '-e', 'NVIM=' .. vim.v.servername, '-e', 'LG_CONFIG_FILE=' .. lazygit_config,
    'lazygit' })
end

return M
