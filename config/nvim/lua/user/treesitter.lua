-- Returns wait(), which waits for the parsers still downloading; setup_nvim calls it, since a headless nvim
-- would otherwise quit before they're installed, and every start would download them again.
local M = { wait = function() end }
local status, ts = pcall(require, 'nvim-treesitter')
if (not status) then return M end

-- nvim-treesitter `main` (the rewrite): no more `nvim-treesitter.configs`.
-- Parsers are installed (async, skipped when present) and compiled with the `tree-sitter` CLI.
ts.setup {}
local installing = ts.install {
  'tsx',
  'typescript',
  'javascript',
  'toml',
  'json',
  'yaml',
  'lua',
  'go',
  'gomod',
  'gosum',
  'gowork',
  'bash',
  'markdown',
  'markdown_inline',
  'hcl',
  'terraform',
  'helm',
  'swift',
  'kotlin',
  'groovy',
  'xml',
}
M.wait = function() installing:wait(300000) end

vim.treesitter.language.register('tsx', 'typescript.tsx')

-- highlighting is built into nvim, the plugin only provides parsers, queries and indent
vim.api.nvim_create_autocmd('FileType', {
  callback = function(args)
    if pcall(vim.treesitter.start, args.buf) then
      vim.bo[args.buf].indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
    end
  end,
})

return M
