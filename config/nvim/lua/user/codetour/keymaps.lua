-- Codetour's ;o and ;l, the review comments' ,n and ;n, the fzf keys inside their pickers and the note
-- window's. Loaded by user/codetour/init.lua; picker_keys is read by user/codetour/picker and
-- user/codetour/review, note_keys by user/codetour/editor.
local status, _ = pcall(require, 'codetour')
if (not status) then return {} end

local M = {}

-- inside the pickers (user/codetour/picker), as fzf keys. remove: delete the tour (;o, asks first) / remove
-- the stop (;l); reword: the stop's note (;l). normal: in normal mode d and r press them too (picker_modes);
-- fzf has no two-key sequences, so d, not dd. send: the review comments to the agent (;n), p as in vim's put;
-- alt-s is AeroSpace's.
-- Switching between the two review pickers, alt plus the letter of the one it opens:
--   to_review  (alt-n, in ;g, user/git/changes): to the comments, ;n. In normal mode n too, which ;g doesn't use.
--   to_changes (alt-g, in ;n): to the changed files, ;g. Not plain g in normal mode: g is the first line in
--   every picker. alt-g is fzf-lua's first line too, so in ;n that is g in normal mode only.
M.picker_keys = {
  remove = 'alt-d',
  reword = 'alt-r',
  normal = 'd:alt-d,r:alt-r',
  send = 'alt-p',
  send_normal = 'p:alt-p',
  to_review = 'alt-n',
  to_review_normal = 'n:alt-n',
  to_changes = 'alt-g',
}

-- note_keys(buf, close): the keys of the window a note is written in (user/codetour/editor); :w saves there
function M.note_keys(buf, close)
  vim.keymap.set('n', 'q', close, { buffer = buf, desc = 'Codetour: close the note without saving' })
end

-- ;o: pick a tour and open it (:CodeTour open names the same thing)
vim.keymap.set('n', ';o', function() require('user.codetour.picker').tours() end,
  { desc = 'Codetour: pick a tour and open it' })

-- ;l: pick a stop of the open tour (:CodeTour list)
vim.keymap.set('n', ';l', function() require('user.codetour.picker').stops() end,
  { desc = 'Codetour: pick a stop of the open tour' })

-- ,n / ;n: the review comment on this line, new or to change / the comments not sent yet, sent to the agent
-- from there (as harpoon's ,m / ;m: add here / pick from the list)
vim.keymap.set('n', ',n', function() require('user.codetour.review').comment() end,
  { desc = 'Codetour: review comment on this line, new or to change' })
vim.keymap.set('n', ';n', function() require('user.codetour.review').pick() end,
  { desc = 'Codetour: review comments, send them to the agent' })

return M
