-- A stop's note as a block above its line, on the page and in the picker's preview: a bar down the left,
-- "stop 4 of 10 · tour" on top, then the whole note wrapped, on a shaded background. The plugin draws one
-- long line that runs off the window and reads like a diagnostic. Used by user/codetour/config (setup) and
-- user/codetour/picker (the preview); user/codetour/tour puts the block in the plugin's place.
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
-- Breaks text at spaces into lines of at most width cells; a longer word gets a line of its own. The note's
-- own line breaks stay, an empty line too (notes written in user/codetour/editor have several lines).
local function wrap(text, width)
  local lines = {}
  if text:match('^%s*$') then return lines end
  for _, paragraph in ipairs(vim.split(text, '\n', { plain = true })) do
    local line = ''
    for word in paragraph:gmatch('%S+') do
      if line == '' then
        line = word
      elseif vim.fn.strdisplaywidth(line .. ' ' .. word) <= width then
        line = line .. ' ' .. word
      else
        table.insert(lines, line)
        line = word
      end
    end
    table.insert(lines, line)
  end
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
-- The plugin draws each note as the block above from now on (user/codetour/tour, draw_notes), in colours
-- that follow the theme.
function M.setup()
  if not require('user.codetour.tour').draw_notes(M.virt_lines) then return end
  set_highlights()
  vim.api.nvim_create_autocmd('ColorScheme', {
    group = vim.api.nvim_create_augroup('user_codetour_notes', { clear = true }),
    callback = set_highlights,
  })
end

return M
