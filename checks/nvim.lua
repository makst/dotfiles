-- nvim.lua <repo> <lua files…>: the nvim checks of check_dotfiles, run by `nvim --clean --headless -l`, so no
-- config or plugin is loaded. Prints one line per problem, prefixed with its check, and a count per check:
--   syntax:   every Lua file compiles
--   requires: every require('user.…') has its file, and every file is required from init.lua (none is dead)
--   plugins:  lua/user/plugins.lua and lazy-lock.json list the same plugins, and the specs use only keys
--             lazy.nvim knows; it ignores the others silently, so `dependecies = …` would do nothing
local repo = arg[1]
local files = { unpack(arg, 2) }
local config = repo .. '/config/nvim'

local function problem(check, message) print(check .. ': ' .. message) end
local function count(check, n) print('count ' .. check .. ' ' .. n) end
local function read(path)
  local f = io.open(path)
  if not f then return nil end
  local text = f:read('*a')
  f:close()
  return text
end

-- syntax
for _, file in ipairs(files) do
  local ok, err = loadfile(repo .. '/' .. file)
  if not ok then problem('syntax', (err:gsub('^' .. vim.pesc(repo) .. '/', ''))) end
end
count('syntax', #files)

-- requires: module user.<name> lives in lua/user/<name>.lua or lua/user/<name>/init.lua (dots in the name are /)
local function module_file(module)
  local base = 'config/nvim/lua/' .. module:gsub('%.', '/')
  for _, candidate in ipairs({ base .. '.lua', base .. '/init.lua' }) do
    if vim.uv.fs_stat(repo .. '/' .. candidate) then return candidate end
  end
end
local required, seen, edges = {}, {}, 0
local function visit(file)
  if seen[file] then return end
  seen[file] = true
  local text = read(repo .. '/' .. file) or ''
  for module in text:gmatch("require%s*%(?%s*['\"](user%.[%w%._-]+)['\"]") do
    edges = edges + 1
    local target = module_file(module)
    -- user.hidden is gitignored and loaded with pcall, so it may be missing
    if target then visit(target) elseif module ~= 'user.hidden' then
      problem('requires', file .. ': require(\'' .. module .. '\'): no such file')
    end
  end
  for module in text:gmatch("pcall%(%s*require%s*,%s*['\"](user%.[%w%._-]+)['\"]") do
    local target = module_file(module)
    if target then visit(target) end
  end
end
visit('config/nvim/init.lua')
for _, file in ipairs(files) do
  if not seen[file] and file:match('^config/nvim/lua/') and not file:match('/user/hidden/') then
    problem('requires', file .. ': nothing requires it, so nvim never loads it')
  end
end
count('requires', edges)

-- plugins: plugins.lua with lazy.nvim replaced by a stub that keeps the specs, and its bootstrap (a git clone
-- when lazy.nvim is missing) skipped
local specs
package.loaded['lazy'] = { setup = function(s) specs = s end }
local fs_stat = vim.uv.fs_stat
vim.uv.fs_stat = function() return { type = 'directory' } end
local ok, err = pcall(dofile, config .. '/lua/user/plugins.lua')
vim.uv.fs_stat = fs_stat
if not ok then
  problem('plugins', 'lua/user/plugins.lua: ' .. tostring(err))
  specs = {}
end

local known = {}
for _, key in ipairs({ 'dir', 'url', 'name', 'dev', 'dependencies', 'enabled', 'cond', 'priority', 'lazy', 'init',
  'opts', 'opts_extend', 'config', 'main', 'build', 'event', 'cmd', 'ft', 'keys', 'branch', 'tag', 'commit',
  'version', 'pin', 'submodules', 'optional', 'specs', 'module', 'import', 'virtual' }) do
  known[key] = true
end
-- a plugin's name, as lazy-lock.json keys it: its name, else the last part of its repo, url or dir
local function name_of(spec, source)
  return spec.name or (tostring(source):match('([^/]+)$'):gsub('%.git$', ''))
end
local plugins = { ['lazy.nvim'] = true }
local add_list
-- add_spec(spec): a plugin given as 'owner/repo' or as a table with the repo first and its options
local function add_spec(spec)
  if type(spec) == 'string' then
    plugins[name_of({}, spec)] = true
  elseif type(spec) == 'table' and type(spec[1]) == 'table' then
    add_list(spec)
  elseif type(spec) == 'table' then
    local source = spec[1] or spec.url or spec.dir
    for key in pairs(spec) do
      if type(key) == 'string' and not known[key] then
        problem('plugins', ('lua/user/plugins.lua: %s has the key %s, which lazy.nvim ignores'):format(source, key))
      end
    end
    plugins[name_of(spec, source)] = true
    if type(spec.dependencies) == 'table' then add_list(spec.dependencies) else add_spec(spec.dependencies) end
  end
end
-- add_list(list): the specs setup() gets, or a plugin's dependencies
add_list = function(list)
  for _, spec in ipairs(list) do add_spec(spec) end
end
add_list(specs)

local lock = vim.json.decode(read(config .. '/lazy-lock.json') or '{}')
local n = 0
for name in pairs(plugins) do
  n = n + 1
  if not lock[name] then
    problem('plugins', name .. ' is in plugins.lua but not pinned in lazy-lock.json: start nvim to pin it, then commit the lock')
  end
end
for name, entry in pairs(lock) do
  if not plugins[name] then
    problem('plugins', name .. ' is pinned in lazy-lock.json but not in plugins.lua: `:Lazy clean` drops it from the lock')
  elseif type(entry) ~= 'table' or not tostring(entry.commit):match('^%x+$') then
    problem('plugins', name .. ' in lazy-lock.json has no commit')
  end
end
count('plugins', n)
