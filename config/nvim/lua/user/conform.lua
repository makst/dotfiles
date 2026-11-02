-- format on save: the project's formatter where one is installed (prettier from node_modules, ruff, ...),
-- otherwise the language server. Formatters that aren't installed are skipped, prettier and stylua also
-- when the project has no config for them (they'd reformat everything, e.g. setext headings in Markdown).
-- Swift: SwiftFormat with a .swiftformat, Apple's swift-format with a .swift-format, nothing otherwise.
-- Kotlin: ktlint when the project's .editorconfig sets it up, nothing otherwise.
-- `:ConformInfo` shows which one a buffer uses.
local status, conform = pcall(require, 'conform')
if (not status) then return end

local util = require('conform.util')
local prettier = { 'prettierd', 'prettier', stop_after_first = true }

-- whether the nearest `name` above the buffer mentions `word`, e.g. an .editorconfig with ktlint settings
local function config_mentions(name, word)
  return function(_, ctx)
    local path = vim.fs.find(name, { path = ctx.dirname, upward = true })[1]
    local file = path and io.open(path)
    if not file then return false end
    local text = file:read('*a')
    file:close()
    return text:find(word, 1, true) ~= nil
  end
end

conform.setup({
  formatters_by_ft = {
    javascript = prettier,
    javascriptreact = prettier,
    typescript = prettier,
    typescriptreact = prettier,
    json = prettier,
    jsonc = prettier,
    yaml = prettier,
    markdown = prettier,
    css = prettier,
    html = prettier,
    go = { 'goimports', 'gofmt', stop_after_first = true },
    python = { 'ruff_organize_imports', 'ruff_format' },
    lua = { 'stylua' },
    sh = { 'shfmt' },
    -- only with the project's own config (see formatters below), never sourcekit-lsp: without a config it
    -- would restyle every file the project formatted differently
    swift = { 'swiftformat', 'swift', stop_after_first = true, lsp_format = 'never' },
    -- the same for kotlin-lsp; projects that format with ktfmt or spotless do it through Gradle (`,aa`)
    kotlin = { 'ktlint', lsp_format = 'never' },
  },
  formatters = {
    prettier = { require_cwd = true },
    prettierd = { require_cwd = true },
    stylua = { require_cwd = true },
    swiftformat = { cwd = util.root_file({ '.swiftformat' }), require_cwd = true },
    swift = { cwd = util.root_file({ '.swift-format' }), require_cwd = true }, -- Apple's swift-format, `swift format`
    ktlint = { condition = config_mentions('.editorconfig', 'ktlint') },
  },
  default_format_opts = { lsp_format = 'fallback' },
  format_on_save = { timeout_ms = 3000 },
})
