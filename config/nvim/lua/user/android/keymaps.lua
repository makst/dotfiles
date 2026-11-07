-- Android keys (,a…), the debug variant only; what each does is in config.lua and docs/mobile.md
local android = require('user.android.config')

local map = function(lhs, rhs, desc)
  vim.keymap.set('n', lhs, rhs, { desc = desc })
end

map('<leader>aa', android.tasks, 'Android: run Gradle tasks')
map('<leader>ab', android.build, 'Android: build')
map('<leader>ar', android.install_and_launch, 'Android: build, install and launch')
map('<leader>at', function() android.run('gradle', './gradlew testDebugUnitTest') end, 'Android: run the unit tests')
map('<leader>ai', function() android.run('gradle', './gradlew connectedDebugAndroidTest') end,
  'Android: run the instrumented tests on the device')
map('<leader>ax', android.stop, 'Android: stop the running Gradle task')
map('<leader>ag', android.toggle_gradle, 'Android: show / hide the Gradle shell')
map('<leader>al', android.logcat, "Android: the app's logcat")
map('<leader>ae', android.start_emulator, 'Android: start an emulator')
map('<leader>ao', android.open_in_studio, 'Android: open this file at this line in Android Studio')
