-- Telescope pickers for codetour, in place of its plain vim.ui.select lists: the tours with their stops in
-- the preview, the open tour's stops with the code around each one. Deleting and rewording happen in the
-- picker, which then refreshes in place.
local status, _ = pcall(require, 'telescope')
if (not status) then return {} end

local pickers = require('telescope.pickers')
local finders = require('telescope.finders')
local previewers = require('telescope.previewers')
local actions = require('telescope.actions')
local action_state = require('telescope.actions.state')
local entry_display = require('telescope.pickers.entry_display')
local conf = require('telescope.config').values
local state = require('codetour.state')

local M = {}

-- stop_line(idx, stop) -> '[1]  path/file.lua:10  ─  note'
-- One stop as the plugin's own :CodeTour buffer shows it, so its 'codetour' syntax colours the tour preview.
local function stop_line(idx, stop)
  local note = stop.note ~= '' and stop.note or '(no note)'
  return string.format('[%d]  %s:%d  ─  %s', idx, vim.fn.fnamemodify(stop.file, ':~:.'), stop.lnum or 1, note)
end

-- refresh(prompt_bufnr, finder)
-- Swaps the picker's results for a fresh finder after a change, keeping the query.
local function refresh(prompt_bufnr, finder)
  action_state.get_current_picker(prompt_bufnr):refresh(finder, { reset_prompt = false })
end

local function stops_finder()
  -- the stops follow edits through extmarks; read where they are now, not where they were saved
  require('codetour.decoration').sync_positions(state.stops())
  local stops = state.stops()
  local displayer = entry_display.create {
    separator = '  ',
    items = { { width = #tostring(#stops) }, { remaining = true } },
  }
  local results = {}
  for idx, stop in ipairs(stops) do
    table.insert(results, { idx = idx, stop = stop, path = string.format('%s:%d', vim.fn.fnamemodify(stop.file, ':~:.'), stop.lnum or 1) })
  end
  return finders.new_table {
    results = results,
    entry_maker = function(item)
      local stop = item.stop
      return {
        value = item,
        -- the note is the overview; the path stays searchable and shows above the preview
        ordinal = stop.note .. ' ' .. item.path,
        filename = stop.file,
        text = stop.note,
        lnum = stop.lnum or 1,
        col = (stop.col or 0) + 1,
        display = function()
          return displayer {
            { tostring(item.idx), 'TelescopeResultsNumber' },
            stop.note ~= '' and stop.note or { '(no note)', 'Comment' },
          }
        end,
      }
    end,
  }
end

local preview_namespace = vim.api.nvim_create_namespace('user_codetour_preview')

-- The stop's file at its line, its note drawn above it as on the page, its path as the title.
local stop_previewer = previewers.new_buffer_previewer {
  title = 'Stop',
  define_preview = function(self, entry)
    local item, winid = entry.value, self.state.winid
    conf.buffer_previewer_maker(item.stop.file, self.state.bufnr, {
      bufname = self.state.bufname,
      winid = winid,
      callback = function(bufnr)
        if not vim.api.nvim_win_is_valid(winid) then return end
        local row = math.min(entry.lnum, vim.api.nvim_buf_line_count(bufnr)) - 1
        local line = vim.api.nvim_buf_get_lines(bufnr, row, row + 1, false)[1] or ''
        vim.api.nvim_buf_clear_namespace(bufnr, preview_namespace, 0, -1)
        vim.api.nvim_buf_set_extmark(bufnr, preview_namespace, row, 0, {
          line_hl_group = 'TelescopePreviewLine',
          virt_lines = item.stop.note ~= '' and require('user.codetour.notes').virt_lines(
            item.stop.note, item.idx, #state.stops(), nil, line:match('^%s*'), vim.api.nvim_win_get_width(winid) - 2
          ) or nil,
          virt_lines_above = row > 0,
        })
        -- a few lines before the stop on top, then its note, then the code it explains
        vim.wo[winid].scrolloff = 0
        vim.api.nvim_win_call(winid, function()
          vim.fn.winrestview({ lnum = row + 1, col = 0, topline = math.max(row - 2, 1) })
        end)
      end,
    })
  end,
}

-- the path as the preview's title; telescope only does that for every picker at once (dynamic_preview_title)
function stop_previewer:title(entry) return entry and entry.value.path or 'Stop' end

-- with_stops(prompt_bufnr, change)
-- Gives change(stops, idx) a copy of the open tour's stops and the selected index, saves the copy back
-- through the plugin (signs, notes and the quickfix list follow) and refreshes the picker.
local function with_stops(prompt_bufnr, change)
  local entry = action_state.get_selected_entry()
  if entry == nil then return end
  local stops = vim.list_extend({}, state.stops())
  change(stops, entry.value.idx)
  state.replace_stops(stops)
  refresh(prompt_bufnr, stops_finder())
end

local function remove_stop(prompt_bufnr)
  with_stops(prompt_bufnr, function(stops, idx) table.remove(stops, idx) end)
end

local function reword_stop(prompt_bufnr)
  local entry = action_state.get_selected_entry()
  if entry == nil then return end
  vim.ui.input({ prompt = 'Note: ', default = entry.value.stop.note }, function(note)
    if note == nil then return end
    with_stops(prompt_bufnr, function(stops, idx)
      stops[idx] = vim.tbl_extend('force', stops[idx], { note = note })
    end)
  end)
end

-- stops(opts)
-- The open tour's stops in order, previewed at their line. Enter jumps there, M-d / dd removes the stop,
-- M-r / r rewords its note; C-s sends them to the quickfix list like any picker.
function M.stops(opts)
  opts = opts or {}
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
  pickers.new(opts, {
    prompt_title = string.format('Tour: %s', tour.name),
    finder = stops_finder(),
    sorter = conf.generic_sorter(opts),
    previewer = stop_previewer,
    attach_mappings = function(_, map)
      map({ 'i', 'n' }, '<M-d>', remove_stop)
      map('n', 'dd', remove_stop)
      map({ 'i', 'n' }, '<M-r>', reword_stop)
      map('n', 'r', reword_stop)
      return true
    end,
  }):find()
end

local function tours_finder()
  local tours = state.tours_with_meta()
  local width = 0
  for _, tour in ipairs(tours) do width = math.max(width, vim.fn.strdisplaywidth(tour.name)) end
  local displayer = entry_display.create {
    separator = '  ',
    items = { { width = 1 }, { width = width }, { remaining = true } },
  }
  return finders.new_table {
    results = tours,
    entry_maker = function(tour)
      local count = string.format('%d %s', tour.stops_count, tour.stops_count == 1 and 'stop' or 'stops')
      return {
        value = tour,
        ordinal = tour.name,
        display = function()
          return displayer {
            { tour.is_active and '●' or '', 'TelescopeResultsSpecialComment' },
            tour.name,
            { count, 'TelescopeResultsComment' },
          }
        end,
      }
    end,
  }
end

local tour_previewer = previewers.new_buffer_previewer {
  title = 'Stops',
  define_preview = function(self, entry)
    -- the open tour is in memory with its live positions; the others are read from disk
    local active = state.data.active_tour
    local tour = (active and active.name == entry.value.name) and active
      or require('codetour.storage').load_tour(entry.value.name)
    local lines = {}
    for idx, stop in ipairs(tour and tour.stops or {}) do
      table.insert(lines, stop_line(idx, stop))
    end
    if #lines == 0 then lines = { '# no stops yet' } end
    vim.api.nvim_buf_set_lines(self.state.bufnr, 0, -1, false, lines)
    vim.bo[self.state.bufnr].filetype = 'codetour'
  end,
}

local function delete_tour(prompt_bufnr)
  local entry = action_state.get_selected_entry()
  if entry == nil then return end
  -- the plugin asks before deleting
  state.delete(entry.value.name)
  refresh(prompt_bufnr, tours_finder())
end

-- tours(opts)
-- The repo's tours (● the open one), the selected tour's stops in the preview. Enter opens the tour: its
-- notes show and its stops fill the quickfix list. M-d / dd deletes the tour, after asking.
function M.tours(opts)
  opts = opts or {}
  state.ensure_loaded()
  if #state.list_tours() == 0 then
    vim.notify('codetour: no tours here yet: :CodeTour create <name>', vim.log.levels.WARN)
    return
  end
  pickers.new(opts, {
    prompt_title = 'Tours',
    finder = tours_finder(),
    sorter = conf.generic_sorter(opts),
    previewer = tour_previewer,
    attach_mappings = function(prompt_bufnr, map)
      actions.select_default:replace(function()
        local entry = action_state.get_selected_entry()
        actions.close(prompt_bufnr)
        if entry then state.open(entry.value.name) end
      end)
      map({ 'i', 'n' }, '<M-d>', delete_tour)
      map('n', 'dd', delete_tour)
      return true
    end,
  }):find()
end

return M
