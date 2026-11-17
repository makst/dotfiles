-- The one file that reaches into codetour.nvim's internal modules (its state, storage, git, decoration, util,
-- anchor, notes and picker modules), beyond the public require('codetour'). An update that moves them breaks
-- here alone, and the version this is written against is pinned in lazy-lock.json (docs/design.md, "Fits in
-- one head", item 6; checks/nvim.lua, "internals", warns on another file that requires them). The functions
-- are what this config does with a tour, not a copy of the plugin's modules; the few that only hand on one
-- call (add, replace_stops, open, delete, names, tours, stops, canonical) are here to keep the modules out
-- of the other files. Each requires the plugin's modules when called, so loading this file loads nothing.
-- Used by user/codetour/review, user/codetour/picker, user/codetour/notes, user/codetour/config and
-- user/git/changes.
local M = {}

local function state() return require('codetour.state') end

-- M.open_tour() -> the open tour ({ name, stops }), or nil when none is
function M.open_tour()
  state().ensure_loaded()
  return state().data.active_tour
end

-- M.names() -> the names of the repo's tours, sorted
function M.names() return state().list_tours() end

-- M.exists(name) -> whether the repo has a tour of that name, open or not
function M.exists(name) return vim.tbl_contains(state().list_tours(), name) end

-- M.tours() -> { { name, stops_count, is_active } }: the repo's tours, for a list of them
function M.tours() return state().tours_with_meta() end

-- M.stops() -> the open tour's stops ({ id, file, lnum, col, note, context }), in order, at the lines last
-- read; {} when no tour is open. The list itself: a change to it goes through M.replace_stops.
function M.stops() return state().stops() end

-- M.stops_now() -> M.stops(), first moved to where the edits since have taken their lines (the plugin
-- follows them with extmarks and writes them back only when it saves)
function M.stops_now()
  require('codetour.decoration').sync_positions(state().stops())
  return state().stops()
end

-- M.stops_of(name) -> the stops of the tour of that name without opening it: the open tour's from memory,
-- with their live positions, another's read from its file; {} when there is no such tour
function M.stops_of(name)
  local active = M.open_tour()
  if active and active.name == name then return active.stops end
  local tour = require('codetour.storage').load_tour(name)
  return tour and tour.stops or {}
end

-- M.add(note): a stop at the cursor of the current window, in the open tour
function M.add(note) state().add(note) end

-- M.replace_stops(stops): the open tour's stops swapped for these (kept ids keep their place in the code);
-- signs, notes and the quickfix list follow, and the tour is saved
function M.replace_stops(stops) state().replace_stops(stops) end

-- M.open(name): opens the tour as :CodeTour open does: notes on, the quickfix list filled, a jump to the
-- first stop
function M.open(name) state().open(name) end

-- M.delete(name): deletes the tour after asking, as :CodeTour delete does
function M.delete(name) state().delete(name) end

-- M.open_quietly(name, then_do): makes the tour of that name the open one, created when there is none, then
-- calls then_do(). Only one tour is open at a time, and the plugin adds and lists stops only in that one.
-- - already open: then_do() at once
-- - none of that name: created, which opens it without moving the cursor; then_do() at once
-- - there but not open (after a restart, or ;o opened another): the plugin's open jumps to the first stop and
--   opens the quickfix list, on the next tick. So after that jump the quickfix list is closed and the window,
--   buffer and view are put back, and only then then_do() runs: a callback, not a return, so what comes next
--   (a stop at the cursor, a picker) sees the cursor where you left it.
function M.open_quietly(name, then_do)
  local active = M.open_tour()
  if active and active.name == name then return then_do() end
  if not M.exists(name) then
    state().create(name)
    return then_do()
  end
  local win, buf, view = vim.api.nvim_get_current_win(), vim.api.nvim_get_current_buf(), vim.fn.winsaveview()
  state().open(name)
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

-- M.drop(name): the open tour, of that name, closed and its file deleted without asking, as :CodeTour delete
-- does once you say yes; nothing remembers it as the last tour
function M.drop(name)
  state().close()
  require('codetour.storage').write_active(nil)
  require('codetour.storage').delete(name)
end

-- M.repo_root() -> the git root of the working directory, which the tours belong to, or nil outside a repo
function M.repo_root()
  local info = require('codetour.git').info()
  return info and info.root
end

-- M.canonical(path) -> the path as the stops have it: absolute, symlinks resolved; nil for no path
function M.canonical(path) return require('codetour.util').canonical(path) end

-- M.draw_notes(block) -> whether it could: the plugin's note drawing replaced, so each stop's note is the
-- virt_lines block(note, idx, total, tour_name, indent) returns, above the stop's line (below line 1, where
-- nvim draws nothing above). It keeps the plugin's namespace, its mark table and its show / hide switch, so
-- :CodeTour toggle-notes and removing a stop still work. Called before codetour's setup, which draws them.
function M.draw_notes(block)
  local ok, notes = pcall(require, 'codetour.notes')
  if not ok then return false end
  local namespace = vim.api.nvim_create_namespace('codetour_notes') -- the plugin's, same name same id
  notes.refresh = function(bufnr, stops, tour_name)
    bufnr = require('codetour.util').actual_bufnr(bufnr)
    if not vim.api.nvim_buf_is_valid(bufnr) or not notes._visible then return end
    vim.api.nvim_buf_clear_namespace(bufnr, namespace, 0, -1)
    notes._buf_marks[bufnr] = {}
    local anchor = require('codetour.anchor')
    for idx, stop in ipairs(stops) do
      local key = stop.id or idx
      local row = anchor.row_of(bufnr, key)
      if row ~= nil and (stop.note or '') ~= '' then
        local line = vim.api.nvim_buf_get_lines(bufnr, row, row + 1, false)[1] or ''
        notes._buf_marks[bufnr][key] = vim.api.nvim_buf_set_extmark(bufnr, namespace, row, 0, {
          virt_lines = block(stop.note, idx, #stops, tour_name, line:match('^%s*')),
          virt_lines_above = row > 0,
        })
      end
    end
  end
  return true
end

-- M.use_pickers(pickers): :CodeTour open (with no name and none to reopen) and :CodeTour list show
-- pickers.tours and pickers.stops instead of the plugin's vim.ui.select lists
function M.use_pickers(pickers)
  local plugin_pickers = require('codetour.picker')
  plugin_pickers.tours = pickers.tours
  plugin_pickers.stops = pickers.stops
end

return M
