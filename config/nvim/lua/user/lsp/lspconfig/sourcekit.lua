-- Swift and Objective-C: sourcekit-lsp ships with Xcode (and the Command Line Tools), so it isn't in Mason.
-- For an Xcode project it needs a buildServer.json in the project root, which `,iS` (xcodebuild.nvim's
-- setup) writes through xcode-build-server; Swift packages work without one. The root stays lspconfig's
-- default (buildServer.json, *.xcodeproj, Package.swift, ...), not the git root: in a repo that holds
-- several apps, each app is its own project. C and C++ are left out so they don't start it in other repos.
if vim.fn.executable('sourcekit-lsp') == 0 then return end

vim.lsp.config('sourcekit', {
  filetypes = { 'swift', 'objc', 'objcpp' },
  -- sourcekit-lsp only notices files added outside nvim (Xcode, git) when it may watch the file system
  capabilities = { workspace = { didChangeWatchedFiles = { dynamicRegistration = true } } },
})
vim.lsp.enable('sourcekit')
