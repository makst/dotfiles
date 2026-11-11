-- fzf-lua pickers for codetour, in place of its plain vim.ui.select lists: the tours with their stops in the
-- preview, the open tour's stops with the code around each one. Deleting and rewording happen in the
-- picker, which then shows the change. Used by user/codetour/config (:CodeTour open, :CodeTour list) and
-- user/codetour/keymaps (;o, ;l), which also has the keys inside them.
local status, fzf = pcall(require, 'fzf-lua')
if (not status) then return {} end

local builtin = require('fzf-lua.previewer.builtin')
local fzf_actions = require('fzf-lua.actions')
local state = require('codetour.state')
local keys = require('user.codetour.keymaps').picker_keys

local M = {}

-- picker(name, opts, keys): every picker's options (user/fzf-lua/config)
local function picker(...) return require('user.fzf-lua.config').picker(...) end
local ansi = fzf.utils.ansi_codes

-- one_line(note) -> the note's lines joined with ⏎, for a list that has one line per stop
local function one_line(note) return (note:gsub('%s*\n%s*', ' ⏎ ')) end

-- stop_line(idx, stop) -> '[1]  path/file.lua:10  ─  note'
-- One stop as the plugin's own :CodeTour buffer shows it, so its 'codetour' syntax colours the tour preview.
local function stop_line(idx, stop)
  local note = stop.note ~= '' and one_line(stop.note) or '(no note)'
  return string.format('[%d]  %s:%d  ─  %s', idx, vim.fn.fnamemodify(stop.file, ':~:.'), stop.lnum or 1, note)
end

-- the stop or tour a picker line is about: each line starts with its index and a tab, which fzf doesn't show
local function index(line) return tonumber((line or ''):match('^(%d+)\t')) end

-- stops_list(fzf_cb): the open tour's stops as "idx<tab>idx  note  path:line", the path dim; a function, so
-- fzf-lua can call it again to show a change
local function stops_list(fzf_cb)
  -- the stops follow edits through extmarks; read where they are now, not where they were saved
  require('codetour.decoration').sync_positions(state.stops())
  local stops = state.stops()
  local width = #tostring(#stops)
  for idx, stop in ipairs(stops) do
    local note = stop.note ~= '' and one_line(stop.note) or ansi.grey('(no note)')
    local where = string.format('%s:%d', vim.fn.fnamemodify(stop.file, ':~:.'), stop.lnum or 1)
    fzf_cb(string.format('%d\t%s  %s  %s', idx, ansi.magenta(string.format('%' .. width .. 'd', idx)), note,
      ansi.grey(where)))
  end
  fzf_cb()
end

local preview_namespace = vim.api.nvim_create_namespace('user_codetour_preview')

-- The stop's file at its line, its note drawn above it as on the page, its path as the title.
local StopPreviewer = builtin.buffer_or_file:extend()

-- not the open file's extmarks: the tour's own note among them would show twice
function StopPreviewer:copy_extmarks() return function() end end

function StopPreviewer:parse_entry(entry_str)
  local idx = index(entry_str)
  local stop = idx and state.stops()[idx]
  if not stop then return {} end
  local entry = StopPreviewer.super.parse_entry(self, string.format('%s:%d:%d:', stop.file, stop.lnum or 1,
    (stop.col or 0) + 1))
  entry.title = string.format(' %s:%d ', vim.fn.fnamemodify(stop.file, ':~:.'), stop.lnum or 1)
  entry.stop, entry.idx = stop, idx
  return entry
end

function StopPreviewer:preview_buf_post(entry, min_winopts)
  StopPreviewer.super.preview_buf_post(self, entry, min_winopts)
  local bufnr, winid = self.preview_bufnr, self.win.preview_winid
  if not entry.stop or not bufnr or not vim.api.nvim_win_is_valid(winid) then return end
  local row = math.min(entry.line, vim.api.nvim_buf_line_count(bufnr)) - 1
  local line = vim.api.nvim_buf_get_lines(bufnr, row, row + 1, false)[1] or ''
  vim.api.nvim_buf_clear_namespace(bufnr, preview_namespace, 0, -1)
  if entry.stop.note ~= '' then
    vim.api.nvim_buf_set_extmark(bufnr, preview_namespace, row, 0, {
      virt_lines = require('user.codetour.notes').virt_lines(
        entry.stop.note, entry.idx, #state.stops(), nil, line:match('^%s*'), vim.api.nvim_win_get_width(winid) - 2
      ),
      virt_lines_above = row > 0,
    })
  end
  -- a few lines before the stop on top, then its note, then the code it explains
  vim.api.nvim_win_call(winid, function()
    vim.fn.winrestview({ lnum = row + 1, col = 0, topline = math.max(row - 2, 1) })
  end)
end

-- change_stops(selected, change)
-- Gives change(stops, idx) a copy of the open tour's stops and the picked index, then saves the copy back
-- through the plugin (signs, notes and the quickfix list follow).
local function change_stops(selected, change)
  local idx = index(selected[1])
  if idx == nil then return end
  local stops = vim.list_extend({}, state.stops())
  change(stops, idx)
  state.replace_stops(stops)
end

local function remove_stop(selected)
  change_stops(selected, function(stops, idx) table.remove(stops, idx) end)
end

-- reword_stop(selected): the stop's note in a window of its own (user/codetour/editor), then back to the
-- picker; saved empty, the stop goes
local function reword_stop(selected)
  local idx = index(selected[1])
  local stop = idx and state.stops()[idx]
  if stop == nil then return end
  require('user.codetour.editor').edit({
    text = stop.note,
    title = string.format('stop %d · %s:%d', idx, vim.fn.fnamemodify(stop.file, ':~:.'), stop.lnum or 1),
    on_save = function(note)
      change_stops(selected, function(stops, i)
        if note == '' then table.remove(stops, i) else stops[i] = vim.tbl_extend('force', stops[i], { note = note }) end
      end)
      fzf.resume()
    end,
  })
end

-- stops([extra]): the open tour's stops in order, previewed at their line. Enter jumps there; the keys to
-- remove a stop and reword its note are in user/codetour/keymaps; C-s sends them to the quickfix list like any
-- picker. extra = { title, actions, normal } adds a picker's own keys on top, as user/codetour/review does.
function M.stops(extra)
  extra = extra or {}
  state.ensure_loaded()
  local tour = state.data.active_tour
  if tour == nil then
    vim.notify('codetour: no tour is open: ;o picks one', vim.log.levels.WARN)
    return
  end
  if #tour.stops == 0 then
    vim.notify(string.format("codetour: '%s' has no stops yet: :CodeTour add <note>", tour.name), vim.log.levels.WARN)
    return
  end
  -- an entry as fzf-lua's file actions take it
  local function as_file(selected)
    local stops = state.stops()
    return vim.tbl_map(function(line)
      local stop = stops[index(line)]
      return string.format('%s:%d:%d:%s', stop.file, stop.lnum or 1, (stop.col or 0) + 1, stop.note)
    end, selected)
  end
  local actions = {
    enter = function(selected, opts) fzf_actions.file_edit(as_file(selected), opts) end,
    ['ctrl-s'] = function(selected, opts) fzf_actions.file_sel_to_qf(as_file(selected), opts) end,
  }
  actions[keys.remove] = { fn = remove_stop, reload = true }
  -- the picker comes back once the note is saved (reword_stop)
  actions[keys.reword] = reword_stop
  fzf.fzf_exec(stops_list, picker(extra.title or ('tour ' .. tour.name), {
    fzf_opts = { ['--delimiter'] = '\t', ['--with-nth'] = '2..', ['--no-sort'] = true, ['--multi'] = true },
    previewer = { _ctor = function() return StopPreviewer end },
    actions = vim.tbl_extend('force', actions, extra.actions or {}),
  }, extra.normal and (keys.normal .. ',' .. extra.normal) or keys.normal))
end

-- tours_list(fzf_cb): the repo's tours as "idx<tab>● name  N stops", ● on the open one
local function tours_list(fzf_cb)
  local tours = state.tours_with_meta()
  local width = 0
  for _, tour in ipairs(tours) do width = math.max(width, vim.fn.strdisplaywidth(tour.name)) end
  for idx, tour in ipairs(tours) do
    local count = string.format('%d %s', tour.stops_count, tour.stops_count == 1 and 'stop' or 'stops')
    fzf_cb(string.format('%d\t%s %s  %s', idx, tour.is_active and ansi.cyan('●') or ' ',
      tour.name .. string.rep(' ', width - vim.fn.strdisplaywidth(tour.name)), ansi.grey(count)))
  end
  fzf_cb()
end

local function tour_at(line) return state.tours_with_meta()[index(line) or 0] end

-- The selected tour's stops, as the plugin's :CodeTour buffer lists them.
local TourPreviewer = builtin.base:extend()

-- a list of stops, not code: no line numbers or cursor line
function TourPreviewer:gen_winopts()
  return vim.tbl_extend('force', TourPreviewer.super.gen_winopts(self), { number = false, cursorline = false })
end

function TourPreviewer:populate_preview_buf(entry_str)
  local meta = tour_at(entry_str)
  if not meta then return end
  -- the open tour is in memory with its live positions; the others are read from disk
  local active = state.data.active_tour
  local tour = (active and active.name == meta.name) and active or require('codetour.storage').load_tour(meta.name)
  local lines = {}
  for idx, stop in ipairs(tour and tour.stops or {}) do
    table.insert(lines, stop_line(idx, stop))
  end
  if #lines == 0 then lines = { '# no stops yet' } end
  local bufnr = self:get_tmp_buffer()
  vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, lines)
  vim.bo[bufnr].filetype = 'codetour'
  self:set_preview_buf(bufnr)
  self.win:update_preview_title(' Stops ')
end

local function delete_tour(selected)
  local tour = tour_at(selected[1])
  -- the plugin asks before deleting
  if tour then state.delete(tour.name) end
end

-- tours(): the repo's tours (● the open one), the selected tour's stops in the preview. Enter opens the
-- tour: its notes show and its stops fill the quickfix list. The key to delete one (after asking) is in
-- user/codetour/keymaps.
function M.tours()
  state.ensure_loaded()
  if #state.list_tours() == 0 then
    vim.notify('codetour: no tours here yet: :CodeTour create <name>', vim.log.levels.WARN)
    return
  end
  local actions = {
    enter = function(selected)
      local tour = tour_at(selected[1])
      if tour then state.open(tour.name) end
    end,
  }
  -- reopened afterwards, as the question is asked on nvim's command line
  actions[keys.remove] = { delete_tour, fzf_actions.resume }
  fzf.fzf_exec(tours_list, picker('tours', {
    fzf_opts = { ['--delimiter'] = '\t', ['--with-nth'] = '2..', ['--no-sort'] = true, ['--no-multi'] = true },
    previewer = { _ctor = function() return TourPreviewer end },
    actions = actions,
  }, keys.normal))
end

return M
