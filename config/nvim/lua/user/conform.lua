-- format on save: the project's formatter where one is installed (prettier from node_modules, ruff, ...),
-- otherwise the language server. Formatters that aren't installed are skipped, prettier and stylua also
-- when the project has no config for them (they'd reformat everything, e.g. setext headings in Markdown).
-- `:ConformInfo` shows which one a buffer uses.
local status, conform = pcall(require, 'conform')
if (not status) then return end

local prettier = { 'prettierd', 'prettier', stop_after_first = true }

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
  },
  formatters = {
    prettier = { require_cwd = true },
    prettierd = { require_cwd = true },
    stylua = { require_cwd = true },
  },
  default_format_opts = { lsp_format = 'fallback' },
  format_on_save = { timeout_ms = 3000 },
})
