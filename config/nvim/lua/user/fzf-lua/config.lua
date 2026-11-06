-- fzf-lua: every picker in nvim (the ; keys in user/fzf-lua/keymaps, codetour's in user/codetour/picker,
-- vim.ui.select, xcodebuild's) runs the real fzf, so it looks and behaves like the shell's and tmux's: fzf
-- reads config/fzf/fzfrc (FZF_DEFAULT_OPTS_FILE, from .fzf.zsh) for the borders, colours and keys, and the
-- normal mode (jj, j/k, q) is the tmux pickers' (picker_modes in config/tmux/picker.zsh).
local status, fzf = pcall(require, 'fzf-lua')
if (not status) then return end

local keymaps = require('user.fzf-lua.keymaps')

local M = {}

-- picker_modes, from the file the tmux pickers source; ~/.config/nvim is a link into the repo
local picker_zsh = vim.fn.fnamemodify(vim.uv.fs_realpath(vim.fn.stdpath('config')) or '', ':h') .. '/tmux/picker.zsh'
local modes_cache = {}

-- modes(name, keys) -> fzf_args
-- fzf's options for the picker's two modes, opening ready to type, with the prompt "<name>> ". keys are the
-- picker's own normal-mode keys, each with the key it presses (e.g. 'd:alt-d'). Quitting goes through fzf-lua's
-- esc action, which keeps the query for ;; (resume); ? in normal mode presses f1 (keymaps.help_actions). Asked from zsh once per name and kept: picker_modes is
-- the one definition of these keys.
local function modes(name, keys)
  local id = name .. '\0' .. (keys or '')
  if modes_cache[id] == nil then
    local out = vim.fn.filereadable(picker_zsh) == 1 and vim.system({ 'zsh', '-fc',
      'source "$1" && picker_modes "$2" insert "$3" "print(esc)+accept" "trigger(f1)" && print -rNn -- $reply', 'zsh', picker_zsh, name, keys or '',
    }):wait() or { code = 1 }
    local args = {}
    if out.code == 0 then
      for _, arg in ipairs(vim.split(out.stdout, '\0', { plain = true })) do
        table.insert(args, fzf.libuv.shellescape(arg))
      end
    end
    modes_cache[id] = args
  end
  return modes_cache[id]
end

-- picker(name, opts, keys) -> opts
-- A picker's options: opts with the prompt "<name>> " and the two modes (see modes).
function M.picker(name, opts, keys)
  return vim.tbl_extend('force', opts or {}, { prompt = name .. '> ', fzf_args = modes(name, keys) })
end

-- keys(): every key with a desc in normal, visual, operator-pending, insert and terminal mode, this buffer's
-- own included, as "mode  key  desc", searched by key and desc (;?). Enter presses a normal-mode key.
-- fzf-lua's keymaps picker can't leave out the keys without a desc.
function M.keys()
  local entries, keys, seen = {}, {}, {}
  local colour = { n = 'blue', x = 'magenta', o = 'yellow', i = 'red', t = 'green' }
  for _, mode in ipairs({ 'n', 'x', 'o', 'i', 't' }) do
    for _, list in ipairs({ vim.api.nvim_buf_get_keymap(0, mode), vim.api.nvim_get_keymap(mode) }) do
      for _, key in ipairs(list) do
        local id = mode .. key.lhs
        if key.desc and key.desc ~= '' and not seen[id] then
          seen[id] = true
          table.insert(keys, { mode = mode, lhs = key.lhs, desc = key.desc })
        end
      end
    end
  end
  table.sort(keys, function(a, b) return a.desc < b.desc end)
  for idx, key in ipairs(keys) do
    table.insert(entries, string.format('%d\t%s  %-14s  %s', idx,
      fzf.utils.ansi_codes[colour[key.mode]](key.mode), key.lhs:gsub(' ', '<Space>'), key.desc))
  end
  fzf.fzf_exec(entries, M.picker('keys', {
    fzf_opts = { ['--delimiter'] = '\t', ['--with-nth'] = '2..', ['--no-multi'] = true },
    actions = {
      enter = function(selected)
        local key = selected[1] and keys[tonumber(selected[1]:match('^%d+'))]
        if key and key.mode == 'n' then
          vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes(key.lhs, true, false, true), 'm', false)
        end
      end,
    },
  }))
end

local rg_opts ='--hidden --glob=!.git/ --column --line-number --no-heading --color=always --smart-case --max-columns=4096 -e'

fzf.setup {
  -- fzf-lua's default profile without 'hide', whose Esc hides the picker in nvim before fzf sees it: Esc is
  -- picker_modes' (clear the filter, then quit), and ;; starts the last picker again with its query
  'border-fused',
  -- the prompt and the list in fzf's own boxes (fzfrc), the preview under them, as in the tmux pickers
  winopts = {
    height = 0.9,
    width = 0.85,
    border = 'none',
    preview = {
      layout = 'vertical',
      vertical = 'down:60%',
      border = 'rounded',
    },
  },
  -- fzfrc's colours (ANSI, so they follow the theme) and its own height inside the window
  fzf_colors = false,
  fzf_opts = { ['--height'] = '100%', ['--cycle'] = true },
  keymap = keymaps.picker_keys,
  actions = { files = keymaps.file_actions },
  files = { cwd_prompt = false },
  buffers = { actions = keymaps.buffer_actions },
  grep = { rg_opts = rg_opts },
  -- vim.ui.select's own prompt names it, e.g. "Start emulator"
  defaults = vim.tbl_extend('force', M.picker('pick'), { actions = keymaps.help_actions }),
}

fzf.register_ui_select(function(ui_opts)
  local name = (ui_opts.prompt or 'pick'):gsub('[%s:>]+$', '')
  return M.picker(name ~= '' and name or 'pick')
end)

return M
