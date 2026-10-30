local status, ts = pcall(require, 'nvim-treesitter')
if (not status) then return end

-- nvim-treesitter `main` (the rewrite): no more `nvim-treesitter.configs`.
-- Parsers are installed (async, skipped when present) and compiled with the `tree-sitter` CLI.
ts.setup {}
ts.install {
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
}

vim.treesitter.language.register('tsx', 'typescript.tsx')

-- highlighting is built into nvim, the plugin only provides parsers, queries and indent
vim.api.nvim_create_autocmd('FileType', {
  callback = function(args)
    if pcall(vim.treesitter.start, args.buf) then
      vim.bo[args.buf].indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
    end
  end,
})
