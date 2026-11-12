-- ;g: the files this branch changes, as a pull request's "Files changed" lists them: everything that differs
-- from where the branch left the default branch, committed or not, new files included. Each shows its status
-- and how many review comments it has (user/codetour/review); the preview is its diff through delta. Enter
-- opens it beside its old side (user/git/diff) to read and comment on with ,n; M-p sends the comments, as in ;n.
-- Used by user/git/keymaps.lua.
local status, fzf = pcall(require, 'fzf-lua')
if (not status) then return {} end

local review_keys = require('user.codetour.keymaps').picker_keys

local M = {}

local ansi = fzf.utils.ansi_codes

-- git(root, args…) -> stdout, or nil when git fails
local function git(root, ...)
  local out = vim.system({ 'git', '-C', root, '-c', 'core.quotePath=false', ... }, { text = true }):wait()
  if out.code ~= 0 then return nil end
  return out.stdout
end

-- base(root) -> rev, name
-- Where this branch left the default branch: the merge-base of HEAD and origin/HEAD (or origin/main,
-- origin/master, main, master, the first that exists). On the default branch that is its upstream, so the
-- list is what isn't pushed yet; with no default branch it is HEAD, so the list is what isn't committed.
local function base(root)
  local default = vim.trim(git(root, 'rev-parse', '--abbrev-ref', 'origin/HEAD') or '')
  if default == '' or default == 'origin/HEAD' then
    default = ''
    for _, name in ipairs({ 'origin/main', 'origin/master', 'main', 'master' }) do
      if git(root, 'rev-parse', '--verify', '--quiet', name) then default = name break end
    end
  end
  local rev = default ~= '' and vim.trim(git(root, 'merge-base', 'HEAD', default) or '') or ''
  if rev == '' then return 'HEAD', 'HEAD' end
  return rev, default
end

-- changes(root, rev) -> { { path, status, old } }
-- Every file that differs between rev and the working tree (git's status letter, old = the path before a
-- rename), then the untracked ones (status '?'), each path from the repo root.
local function changes(root, rev)
  local files = {}
  for _, line in ipairs(vim.split(git(root, 'diff', '--name-status', '-M', rev) or '', '\n', { trimempty = true })) do
    local fields = vim.split(line, '\t', { plain = true })
    local letter = fields[1]:sub(1, 1)
    if #fields == 3 then
      table.insert(files, { path = fields[3], status = letter, old = fields[2] })
    else
      table.insert(files, { path = fields[2], status = letter })
    end
  end
  for _, path in ipairs(vim.split(git(root, 'ls-files', '--others', '--exclude-standard') or '', '\n', { trimempty = true })) do
    table.insert(files, { path = path, status = '?' })
  end
  table.sort(files, function(a, b) return a.path < b.path end)
  return files
end

local colour = { A = 'green', ['?'] = 'green', M = 'yellow', D = 'red', R = 'blue', C = 'blue' }

-- line(idx, file, count) -> 'idx<tab>status<tab>old path<tab>path<tab>M  path/file.lua  · 2 comments'
-- fzf shows the last field only; the others are for the preview (and the index for the actions)
local function line(idx, file, count)
  local name = file.old and string.format('%s → %s', file.old, file.path) or file.path
  local comments = count > 0 and ansi.grey(string.format('  · %d %s', count, count == 1 and 'comment' or 'comments'))
    or ''
  return table.concat({ idx, file.status, file.old or file.path, file.path,
    string.format('%s  %s%s', ansi[colour[file.status] or 'grey'](file.status), name, comments) }, '\t')
end

-- preview(root, rev) -> fzf's preview command: the picked file's diff against rev through delta, as git's
-- pager shows it; a new file's against nothing. fzf fills in and quotes the fields ({2} status, {3} the old
-- path, {4} the path) and sets the preview's width, which a command fzf-lua runs itself wouldn't get.
local function preview(root, rev)
  local esc = fzf.libuv.shellescape
  return string.format("cd %s && if [ {2} = '?' ]; then git diff --no-index -- /dev/null {4}; "
    .. 'else git diff -M %s -- {3} {4}; fi | delta --width=$FZF_PREVIEW_COLUMNS', esc(root), esc(rev))
end

-- open(root, rev, file): the file beside its old side, in this window; a deleted file as it was at rev.
-- A diff already open (the last file picked here) is closed first.
local function open(root, rev, file)
  require('user.git.diff').close()
  vim.cmd('diffoff!')
  if file.status == 'D' then
    vim.cmd('Gedit ' .. vim.fn.fnameescape(rev .. ':' .. file.path))
    return
  end
  vim.cmd.edit(vim.fn.fnameescape(vim.fs.joinpath(root, file.path)))
  require('user.git.diff').open(rev)
end

-- pick(opts): the changed files of the repo at the working directory. opts.quit: Esc quits nvim too, for an
-- nvim started only for the picker (greview in zsh/functions/git.zsh)
function M.pick(opts)
  opts = opts or {}
  local root = vim.trim(git(vim.fn.getcwd(), 'rev-parse', '--show-toplevel') or '')
  if root == '' then return vim.notify('git: not in a git repo', vim.log.levels.WARN) end
  local rev, name = base(root)
  local files = changes(root, rev)
  if #files == 0 then return vim.notify('git: nothing changed since ' .. name) end

  local counts, canonical = require('user.codetour.review').counts(), require('codetour.util').canonical
  local entries = {}
  for idx, file in ipairs(files) do
    local full = vim.fs.joinpath(root, file.path)
    table.insert(entries, line(idx, file, counts[canonical(full) or full] or 0))
  end
  local function picked(selected) return files[tonumber((selected[1] or ''):match('^(%d+)\t'))] end

  local actions = {
    enter = function(selected)
      local file = picked(selected)
      if file then open(root, rev, file) end
    end,
  }
  -- Esc reaches fzf-lua as the action esc (picker_modes, user/fzf-lua/config)
  if opts.quit then actions.esc = function() vim.cmd('qall') end end
  actions[review_keys.send] = { fn = function() require('user.codetour.review').send_all() end, desc = 'send-to-agent' }

  fzf.fzf_exec(entries, require('user.fzf-lua.config').picker('changes since ' .. name, {
    fzf_opts = { ['--delimiter'] = '\t', ['--with-nth'] = '5', ['--no-multi'] = true },
    preview = preview(root, rev),
    actions = actions,
  }, review_keys.send_normal))
end

return M
