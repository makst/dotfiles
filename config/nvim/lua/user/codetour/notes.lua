-- A stop's note as a block above its line, on the page and in the telescope preview: a bar down the left,
-- "stop 4 of 10 · tour" on top, then the whole note wrapped, on a shaded background. The plugin draws one
-- long line that runs off the window and reads like a diagnostic.
local M = {}

local WIDTH = 100 -- the block's width at most, bar included

-- set_highlights()
-- The block's colours, taken from the theme's own groups (no hex) so they follow change_theme: the cursor
-- line's shade, the text bold, the bar and the header in the colour of the stop's sign.
local function set_highlights()
  local function hl(name) return vim.api.nvim_get_hl(0, { name = name, link = false }) end
  local shade, text, accent = hl('CursorLine'), hl('Normal'), hl('Special')
  local function group(fg, bold)
    return { fg = fg.fg, ctermfg = fg.ctermfg, bg = shade.bg, ctermbg = shade.ctermbg, bold = bold }
  end
  vim.api.nvim_set_hl(0, 'CodetourNote', group(text, true))
  vim.api.nvim_set_hl(0, 'CodetourNoteTitle', group(accent, true))
  vim.api.nvim_set_hl(0, 'CodetourNoteBar', group(accent, false))
end

-- wrap(text, width) -> { 'line', … }
-- Breaks text at spaces into lines of at most width cells; a longer word gets a line of its own.
local function wrap(text, width)
  local lines, line = {}, ''
  for word in text:gmatch('%S+') do
    if line == '' then
      line = word
    elseif vim.fn.strdisplaywidth(line .. ' ' .. word) <= width then
      line = line .. ' ' .. word
    else
      table.insert(lines, line)
      line = word
    end
  end
  if line ~= '' then table.insert(lines, line) end
  return lines
end

-- M.virt_lines(note, idx, total, tour_name, indent, width) -> virt_lines for nvim_buf_set_extmark
-- The block for one stop, indented like its line, every row padded to the same width so the shade is a
-- rectangle. At most WIDTH wide, less when the window (width) or the editor is narrower.
function M.virt_lines(note, idx, total, tour_name, indent, width)
  width = math.min(width or WIDTH, WIDTH, vim.o.columns - 8) - vim.fn.strdisplaywidth(indent)
  local inner = math.max(width - 3, 20) -- '▌ ' and one cell of shade on the right
  local function row(text, group)
    local pad = string.rep(' ', inner - vim.fn.strdisplaywidth(text) + 1)
    return { { indent }, { '▌ ', 'CodetourNoteBar' }, { text .. pad, group } }
  end
  local title = string.format('stop %d of %d', idx, total) .. (tour_name and (' · ' .. tour_name) or '')
  local out = { row(title, 'CodetourNoteTitle') }
  for _, line in ipairs(wrap(note, inner)) do
    table.insert(out, row(line, 'CodetourNote'))
  end
  return out
end

-- M.setup()
-- Replaces the plugin's note drawing (codetour.notes.refresh) with the block above. It keeps the plugin's
-- namespace, its mark table and its show / hide switch, so :CodeTour toggle-notes and removing a stop
-- still work. Written against the version pinned in lazy-lock.json.
function M.setup()
  local ok, notes = pcall(require, 'codetour.notes')
  if not ok then return end
  set_highlights()
  vim.api.nvim_create_autocmd('ColorScheme', {
    group = vim.api.nvim_create_augroup('user_codetour_notes', { clear = true }),
    callback = set_highlights,
  })

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
          virt_lines = M.virt_lines(stop.note, idx, #stops, tour_name, line:match('^%s*')),
          virt_lines_above = row > 0, -- nvim draws nothing above line 1; the plugin puts it below there too
        })
      end
    end
  end
end

return M
