-- Kotlin: JetBrains' kotlin-lsp (Brewfile cask), built on IntelliJ, so it understands Gradle projects,
-- Android ones included, as Android Studio does. Its server is `intellij-server` (lspconfig's default
-- command), but the cask only links the deprecated `kotlin-lsp` wrapper, so the server is taken from next to
-- it. The root is the nearest settings.gradle(.kts) or build.gradle(.kts). The first start in a project
-- imports it through Gradle, which takes a while: completion and go-to-definition arrive after.
local server = vim.fn.exepath('intellij-server')
if server == '' and vim.fn.executable('kotlin-lsp') == 1 then
  server = vim.fs.dirname(vim.fn.resolve(vim.fn.exepath('kotlin-lsp'))) .. '/bin/intellij-server'
end
if vim.fn.executable(server) == 0 then return end

vim.lsp.config('kotlin_lsp', {
  cmd = { server, '--stdio' },
})
vim.lsp.enable('kotlin_lsp')
