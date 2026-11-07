-- The jobs nvim hands to tmux (docs/design.md, "One tool per job"), at nvim's working directory: two shells that
-- keep running in a tmux pane below nvim, and lazygit in a tmux popup over it. keymaps.lua binds them; outside
-- tmux they only say so. run() and interrupt() type into such a shell, for user/android's Gradle and logcat.
local M = {}

local function in_tmux()
  if vim.env.TMUX then return true end
  vim.notify('needs tmux', vim.log.levels.WARN)
end

local scratch = vim.fn.expand('~/.config/tmux/scratch')

-- scratch(name, dir): the shell `name` for `dir` (default: the working directory), shown below nvim or hidden
-- (config/tmux/scratch)
function M.scratch(name, dir)
  if not in_tmux() then return end
  vim.system({ scratch, name, dir or vim.fn.getcwd() })
end

-- the pane of the shell `name` for `dir`, shown below nvim with the cursor staying in nvim
local function shown(name, dir)
  if not in_tmux() then return end
  local out = vim.system({ scratch, '--show', name, dir }):wait()
  if out.code ~= 0 then
    vim.notify('scratch: ' .. vim.trim(out.stderr or ''), vim.log.levels.WARN)
    return
  end
  return vim.trim(out.stdout)
end

local function keys(pane, ...)
  vim.system({ 'tmux', 'send-keys', '-t', pane, ... }):wait()
end

-- interrupt(name, dir): Ctrl-C to the shell `name` for `dir`, showing it
function M.interrupt(name, dir)
  local pane = shown(name, dir)
  if pane then keys(pane, 'C-c') end
end

-- run(name, dir, cmd): types `cmd` into the shell `name` for `dir` and shows it. What still runs there is
-- stopped first, and the command waits for the shell's prompt, so it doesn't go to the old program's input
-- (Gradle reads it); Ctrl-C also gives a fresh line in insert mode, whatever mode zsh was left in.
function M.run(name, dir, cmd)
  local pane = shown(name, dir)
  if not pane then return end
  keys(pane, 'C-c')
  vim.wait(3000, function()
    local out = vim.system({ 'tmux', 'display', '-p', '-t', pane, '#{pane_current_command}' }):wait()
    return vim.trim(out.stdout or '') == 'zsh'
  end, 100)
  keys(pane, '-l', cmd)
  keys(pane, 'Enter')
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
