-- Android: build, install, run and test a Gradle project from nvim, and jump to Android Studio for what only
-- it does (layout preview, the debugger, profilers). Everything runs through the project's own ./gradlew and
-- adb in a terminal split at the project root (the directory with gradlew), one per project, so its output
-- stays readable and `,ax` can stop it. The app module is the one whose build file applies the Android
-- application plugin; its package name is read from the APK it built, so applicationIdSuffix works too.
-- Only the debug variant has keys (keymaps.lua): other variants and tasks go through `,aa`.
local status_ok, toggleterm = pcall(require, 'toggleterm')
if not status_ok then return {} end
toggleterm.setup {} -- the only user of toggleterm; other shells are tmux popups (user/tmux)

local M = {}

local Terminal = require('toggleterm.terminal').Terminal

local terminals = {} -- [root .. name] = Terminal

local function project_root()
  local root = vim.fs.root(0, 'gradlew') or vim.fs.root(vim.fn.getcwd(), 'gradlew')
  if not root then vim.notify('no gradlew above this file or in the cwd', vim.log.levels.WARN) end
  return root
end

local function terminal(root, name)
  local key = root .. name
  terminals[key] = terminals[key] or Terminal:new({
    dir = root, direction = 'horizontal', hidden = true, close_on_exit = false,
  })
  return terminals[key]
end

-- runs `cmd` in the project's terminal `name` ('gradle' or 'logcat') and keeps the cursor where it was
function M.run(name, cmd)
  local root = project_root()
  if not root then return end
  local term = terminal(root, name)
  if not term:is_open() then term:open() end
  term:send(type(cmd) == 'function' and cmd(root) or cmd, true)
end

-- the directory of the app module under `root`, e.g. 'app'
local function app_module(root)
  for name, type in vim.fs.dir(root) do
    if type == 'directory' then
      for _, file in ipairs({ 'build.gradle.kts', 'build.gradle' }) do
        local f = io.open(root .. '/' .. name .. '/' .. file)
        if f then
          local text = f:read('*a')
          f:close()
          if text:find('android.application', 1, true) then return name end
        end
      end
    end
  end
  return 'app'
end

-- shell code for the package name of the last debug APK the app module built, via the SDK's aapt2
local function package_name(module)
  local aapt2 = vim.fn.glob('$ANDROID_HOME/build-tools/*/aapt2', false, true)
  return ('"$(%s dump packagename "$(ls -t %s/build/outputs/apk/debug/*.apk | head -1)")"')
      :format(aapt2[#aapt2] or 'aapt2', module)
end

local function install_and_launch(root)
  local module = app_module(root)
  return ('./gradlew :%s:installDebug && adb shell monkey -p %s -c android.intent.category.LAUNCHER 1 > /dev/null')
      :format(module, package_name(module))
end

local function logcat(root)
  return ('adb logcat -v color --pid="$(adb shell pidof -s %s)"'):format(package_name(app_module(root)))
end

function M.start_emulator()
  local avds = vim.fn.systemlist({ 'emulator', '-list-avds' })
  if vim.v.shell_error ~= 0 or #avds == 0 then
    vim.notify('no emulators: create one in Android Studio, Device Manager', vim.log.levels.WARN)
    return
  end
  vim.ui.select(avds, { prompt = 'Start emulator' }, function(avd)
    if avd then vim.fn.jobstart({ 'emulator', '-avd', avd }, { detach = true }) end
  end)
end

-- tasks(): asks for Gradle tasks and runs them
function M.tasks()
  vim.ui.input({ prompt = './gradlew ' }, function(tasks)
    if tasks and tasks ~= '' then M.run('gradle', './gradlew ' .. tasks) end
  end)
end

function M.build()
  M.run('gradle', function(root) return ('./gradlew :%s:assembleDebug'):format(app_module(root)) end)
end

function M.install_and_launch() M.run('gradle', install_and_launch) end
function M.logcat() M.run('logcat', logcat) end

-- stop(): Ctrl-C to the project's Gradle terminal
function M.stop()
  local root = project_root()
  local term = root and terminals[root .. 'gradle']
  if term and term.job_id then vim.fn.chansend(term.job_id, '\x03') end
end

function M.toggle_gradle()
  local root = project_root()
  if root then terminal(root, 'gradle'):toggle() end
end

-- open_in_studio(): the same file and line in Android Studio, which opens it in the window that already has
-- the project
function M.open_in_studio()
  if vim.fn.executable('studio') == 0 then
    vim.notify('studio not found: needs Android Studio', vim.log.levels.WARN)
    return
  end
  vim.fn.jobstart({ 'studio', '--line', tostring(vim.fn.line('.')), vim.api.nvim_buf_get_name(0) }, { detach = true })
end

return M
