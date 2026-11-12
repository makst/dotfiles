-- Review comments for the Claude Code agent working in this repo: each comment is a stop of the code tour
-- "review", so it shows above its line like any tour note and follows edits. ;n lists the ones not sent yet
-- and sends them to the agent's tmux pane as one message. Used by user/codetour/keymaps (,n and ;n) and
-- user/git/changes (;g: the comment counts, M-p sends).
local status, state = pcall(require, 'codetour.state')
if (not status) then return {} end

local keys = require('user.codetour.keymaps').picker_keys

local M = {}

-- one per git root, so each agent's worktree has its own; ignored in every repo (config/git/ignore)
local TOUR = 'review'

-- open_review(then_do): makes "review" the open tour, then calls then_do(). The plugin adds and lists stops
-- only in the open tour, and only one tour is open at a time (;o may have opened another). Three cases:
-- - already open: then_do() at once
-- - no review tour yet: created, which opens it without moving the cursor; then_do() at once
-- - there but not open (after a restart, or ;o): the plugin's open also jumps to the first stop and opens the
--   quickfix list, on the next tick. Commenting shouldn't move you, so after that jump the quickfix list is
--   closed and the window, buffer and view are put back, and only then then_do() runs: a callback, not a
--   return, so what comes next (a comment at the cursor, the ;n picker) sees the cursor where you left it.
local function open_review(then_do)
  state.ensure_loaded()
  local active = state.data.active_tour
  if active and active.name == TOUR then return then_do() end
  if not vim.tbl_contains(state.list_tours(), TOUR) then
    state.create(TOUR)
    return then_do()
  end
  local win, buf, view = vim.api.nvim_get_current_win(), vim.api.nvim_get_current_buf(), vim.fn.winsaveview()
  state.open(TOUR)
  -- scheduled after the plugin's own cfirst + cwindow, so it runs after them
  vim.schedule(function()
    vim.cmd('cclose')
    if vim.api.nvim_win_is_valid(win) and vim.api.nvim_buf_is_valid(buf) then
      vim.api.nvim_set_current_win(win)
      vim.api.nvim_win_set_buf(win, buf)
      vim.fn.winrestview(view)
    end
    then_do()
  end)
end

-- drop(): the review tour is done with (sent, or its last comment deleted): closed and its file deleted, as
-- :CodeTour delete does without asking
local function drop()
  state.close()
  require('codetour.storage').write_active(nil)
  require('codetour.storage').delete(TOUR)
end

-- comment(): the review comment on the cursor line in a window of its own (user/codetour/editor): a new one,
-- or the one already there to change. Saving it empty deletes it. The tour is created on the first save, so
-- closing without saving leaves nothing behind.
function M.comment()
  local name = vim.api.nvim_buf_get_name(0)
  if name == '' then return vim.notify('codetour: this buffer has no file', vim.log.levels.WARN) end
  -- the old side of a diff (fugitive's, or user/git/diff's empty one) is a revision, not a file to comment on
  if name:match('^%a+://') or vim.b.git_empty_side then
    return vim.notify('codetour: comment on the file\'s side of the diff', vim.log.levels.WARN)
  end
  local win, lnum = vim.api.nvim_get_current_win(), vim.api.nvim_win_get_cursor(0)[1]
  local file = require('codetour.util').canonical(name) or name
  local title = string.format('review · %s:%d', vim.fn.fnamemodify(name, ':~:.'), lnum)

  local function edit(stop)
    require('user.codetour.editor').edit({ text = stop and stop.note or '', title = title, at_cursor = true,
      on_save = function(text)
        if stop == nil then
          if text == '' then return end
          -- state.add takes the line from the current window's cursor
          return open_review(function() vim.api.nvim_win_call(win, function() state.add(text) end) end)
        end
        local stops = vim.tbl_filter(function(other) return other.id ~= stop.id or text ~= '' end, state.stops())
        if #stops == 0 then return drop() end
        stops = vim.tbl_map(function(other)
          return other.id == stop.id and vim.tbl_extend('force', other, { note = text }) or other
        end, stops)
        state.replace_stops(stops)
      end })
  end

  state.ensure_loaded()
  if not vim.tbl_contains(state.list_tours(), TOUR) then return edit(nil) end
  open_review(function()
    -- where the stops are now, as edits move them
    require('codetour.decoration').sync_positions(state.stops())
    for _, stop in ipairs(state.stops()) do
      if stop.file == file and stop.lnum == lnum then return edit(stop) end
    end
    edit(nil)
  end)
end

-- message(stops) -> text
-- The comments as one prompt, in file and line order: path:line from the repo root, the line as it read when
-- commented, the comment.
local function message(stops)
  local root = require('codetour.git').info()
  root = root and root.root
  stops = vim.list_extend({}, stops)
  table.sort(stops, function(a, b)
    if a.file ~= b.file then return a.file < b.file end
    return (a.lnum or 1) < (b.lnum or 1)
  end)
  local parts = { 'Review comments on your changes. The quoted line is how it read when I commented; line '
    .. 'numbers may have moved since. Address each one, then say what you changed.' }
  for idx, stop in ipairs(stops) do
    local file = stop.file
    if root and file:sub(1, #root + 1) == root .. '/' then file = file:sub(#root + 2) end
    local lines = { string.format('%d. %s:%d', idx, file, stop.lnum or 1) }
    if stop.context and stop.context ~= '' then table.insert(lines, '   > ' .. stop.context) end
    for _, line in ipairs(vim.split(stop.note, '\n', { plain = true })) do
      table.insert(lines, '   ' .. line)
    end
    table.insert(parts, table.concat(lines, '\n'))
  end
  return table.concat(parts, '\n\n')
end

-- tmux(args…) -> stdout, or nil when tmux fails
local function tmux(...)
  local out = vim.system({ 'tmux', ... }, { text = true }):wait()
  if out.code ~= 0 then return nil end
  return out.stdout
end

-- agent_panes(root) -> { { id, label } }
-- The Claude Code panes working in root: tmux's @claude-agent (config/tmux/tmux.conf) picks the panes with
-- an agent, their directory the ones here. root's own agent worktrees (.claude/worktrees/) are other agents.
local function agent_panes(root)
  local out = tmux('list-panes', '-a', '-f', '#{E:@claude-agent}', '-F',
    '#{pane_id}\t#{pane_current_path}\t#{session_name}:#{window_name}  #{pane_title}')
  local panes = {}
  for _, line in ipairs(vim.split(out or '', '\n', { trimempty = true })) do
    local id, path, label = line:match('^(%S+)\t([^\t]*)\t(.*)$')
    local inside = path == root or (path and path:sub(1, #root + 1) == root .. '/'
      and not path:sub(#root + 1):match('^/%.claude/worktrees/'))
    if id and inside then table.insert(panes, { id = id, label = label }) end
  end
  return panes
end

-- paste(pane, text): the text into the pane's prompt as one paste, not sent, and that pane focused, so you
-- read it and press Enter. The tmux buffer "review" keeps the last one (C-a P), in case the prompt is cleared.
local function paste(pane, text)
  local loaded = vim.system({ 'tmux', 'load-buffer', '-b', 'review', '-' }, { stdin = text }):wait().code == 0
  if not loaded or not tmux('paste-buffer', '-p', '-b', 'review', '-t', pane) then
    vim.notify('codetour: tmux could not paste into ' .. pane, vim.log.levels.ERROR)
    return false
  end
  -- switch-client last: it fails without a client and would stop the commands after it
  tmux('select-window', '-t', pane, ';', 'select-pane', '-t', pane, ';', 'switch-client', '-t', pane)
  return true
end

-- send(): every comment of the review to the agent, then off the tour; the tour goes once it's empty.
-- With several agents here (agent_review's reviewer sits beside the author), it asks which one.
local function send()
  require('codetour.decoration').sync_positions(state.stops())
  local stops = state.stops()
  if #stops == 0 then return end
  local text = message(stops)
  -- the comments are in the agent's prompt and the tmux buffer now
  local function done()
    drop()
    vim.notify(string.format('codetour: %d review %s sent', #stops, #stops == 1 and 'comment' or 'comments'))
  end
  local info = require('codetour.git').info()
  local panes = (vim.env.TMUX and info) and agent_panes(info.root) or {}
  if #panes == 0 then
    vim.fn.setreg('+', text)
    vim.notify('codetour: no Claude Code pane in this repo; the comments are on the clipboard',
      vim.log.levels.WARN)
    done()
  elseif #panes == 1 then
    if paste(panes[1].id, text) then done() end
  else
    vim.ui.select(panes, { prompt = 'Send to', format_item = function(pane) return pane.label end },
      function(pane) if pane and paste(pane.id, text) then done() end end)
  end
end

-- has_review() -> whether there are comments not sent yet; says so when there are none
local function has_review()
  state.ensure_loaded()
  if vim.tbl_contains(state.list_tours(), TOUR) then return true end
  vim.notify('codetour: no review comments here: ,n adds one', vim.log.levels.WARN)
end

-- send_all(): the comments to the agent from outside ;n (user/git/changes, ;g's M-p)
function M.send_all()
  if has_review() then open_review(send) end
end

-- counts() -> { [file] = n }: how many comments not sent yet each file has, by full path, without opening the
-- tour (user/git/changes shows them next to each changed file)
function M.counts()
  state.ensure_loaded()
  local active = state.data.active_tour
  local stops
  if active and active.name == TOUR then
    stops = state.stops()
  else
    local tour = vim.tbl_contains(state.list_tours(), TOUR) and require('codetour.storage').load_tour(TOUR)
    stops = tour and tour.stops or {}
  end
  local counts = {}
  for _, stop in ipairs(stops) do counts[stop.file] = (counts[stop.file] or 0) + 1 end
  return counts
end

-- pick(): the comments not sent yet, as the stops picker of a tour, with one more key: send them all
function M.pick()
  if not has_review() then return end
  local actions = {}
  actions[keys.send] = { fn = send, desc = 'send-to-agent' }
  open_review(function()
    require('user.codetour.picker').stops({ title = 'review', actions = actions, normal = keys.send_normal })
  end)
end

return M
