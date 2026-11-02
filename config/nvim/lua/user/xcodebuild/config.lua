-- xcodebuild.nvim: build, run, test an Xcode project on a simulator or device without leaving nvim.
-- Needs Xcode, xcode-build-server and xcbeautify (Brewfile); `:checkhealth xcodebuild` lists what's missing.
-- Per project, `,iS` picks the project, scheme and device and writes .nvim/xcodebuild/settings.json and
-- buildServer.json into it (both belong in the project's .gitignore).
local status_ok, xcodebuild = pcall(require, 'xcodebuild')
if not status_ok then return end

xcodebuild.setup({})
