-- A floating window to write a stop's note in: an ordinary markdown buffer, so several lines and all of vim's
-- keys. :w saves and closes (:wq and ZZ too); q in normal mode, :q or leaving the window closes without
-- saving. Used by user/codetour/review (,n) and user/codetour/picker (M-r in ;l and ;n).
local M = {}

-- M.edit(opts)
-- opts.text: the note so far ('' for a new one); opts.title: the window's title; opts.at_cursor: open just
-- below the cursor line, else in the middle of the editor; opts.on_save(text): called with the text, blank
-- lines and spaces trimmed at both ends, '' when it was saved empty.
function M.edit(opts)
  local buf = vim.api.nvim_create_buf(false, true)
  -- acwrite: :w runs the BufWriteCmd below instead of writing a file; it needs a name
  vim.bo[buf].buftype, vim.bo[buf].bufhidden, vim.bo[buf].filetype = 'acwrite', 'wipe', 'markdown'
  vim.api.nvim_buf_set_name(buf, 'codetour-note://' .. buf)
  -- prose, not code: blink.cmp's menu of words and snippets would cover what you're writing
  vim.b[buf].completion = false
  local lines = vim.split(opts.text or '', '\n', { plain = true })
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
  vim.bo[buf].modified = false

  local width = math.min(80, vim.o.columns - 4)
  local height = math.min(math.max(#lines + 2, 6), 20)
  local config = {
    width = width, height = height, style = 'minimal', border = 'rounded',
    title = ' ' .. opts.title .. ' ', title_pos = 'center',
    footer = ' :w save · q close · save it empty to delete ', footer_pos = 'center',
  }
  if opts.at_cursor then
    config.relative, config.row, config.col = 'cursor', 1, 0
  else
    config.relative = 'editor'
    config.row, config.col = math.floor((vim.o.lines - height) / 2), math.floor((vim.o.columns - width) / 2)
  end
  local win = vim.api.nvim_open_win(buf, true, config)
  vim.wo[win].wrap, vim.wo[win].linebreak = true, true

  local function close()
    if vim.api.nvim_win_is_valid(win) then vim.api.nvim_win_close(win, true) end
  end
  vim.api.nvim_create_autocmd('BufWriteCmd', {
    buffer = buf,
    callback = function()
      local text = table.concat(vim.api.nvim_buf_get_lines(buf, 0, -1, false), '\n')
      text = (text:gsub('^%s+', ''):gsub('%s+$', ''))
      vim.bo[buf].modified = false
      -- after the write, so :wq's quit finds the window still there
      vim.schedule(function()
        close()
        opts.on_save(text)
      end)
    end,
  })
  -- a note left behind in a floating window would hide the code under it
  vim.api.nvim_create_autocmd('WinLeave', { buffer = buf, once = true, callback = function() vim.schedule(close) end })
  require('user.codetour.keymaps').note_keys(buf, close)

  if opts.text == nil or opts.text == '' then
    vim.cmd('startinsert')
  else
    vim.api.nvim_win_set_cursor(win, { #lines, #lines[#lines] })
  end
end

return M
