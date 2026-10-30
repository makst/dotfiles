-- lazy.nvim bootstraps itself on first start. Versions are pinned in lazy-lock.json
-- (`:Lazy restore` installs exactly those, `:Lazy update` moves them).
local lazypath = vim.fn.stdpath('data') .. '/lazy/lazy.nvim'
if not vim.uv.fs_stat(lazypath) then
  local out = vim.fn.system({
    'git', 'clone', '--filter=blob:none', '--branch=stable',
    'https://github.com/folke/lazy.nvim.git', lazypath,
  })
  if vim.v.shell_error ~= 0 then
    print('Could not install lazy.nvim:\n' .. out)
    return
  end
end
vim.opt.rtp:prepend(lazypath)

require('lazy').setup({
  'chriskempson/base16-vim',
  'nvim-lua/plenary.nvim', -- Common utilities

  -- 'navarasu/onedark.nvim',
  'nvimdev/lspsaga.nvim', -- LSP UIs
  'onsails/lspkind.nvim', -- vscode-like pictograms
  'hrsh7th/cmp-buffer', -- nvim-cmp source for buffer words
  'hrsh7th/cmp-nvim-lsp', -- nvim-cmp source for neovim's built-in LSP
  'hrsh7th/nvim-cmp', -- Completion
  'hrsh7th/cmp-nvim-lsp-signature-help',
  'saadparwaiz1/cmp_luasnip',

  -- status line
  'nvim-lualine/lualine.nvim',

  -- LSP
  'mason-org/mason.nvim',
  'mason-org/mason-lspconfig.nvim',
  'neovim/nvim-lspconfig',

  'L3MON4D3/LuaSnip',
  'rafamadriz/friendly-snippets',
  { 'nvim-treesitter/nvim-treesitter', build = ':TSUpdate' },
  'aaronik/treewalker.nvim', -- replaces tree-climber, which needs the removed nvim-treesitter APIs
  'windwp/nvim-autopairs',
  'windwp/nvim-ts-autotag',
  'hashivim/vim-terraform',

  {
    -- 0.2.x: 0.1.x calls nvim-treesitter APIs removed in its rewrite (ft_to_lang) and deprecated vim.lsp APIs
    'nvim-telescope/telescope.nvim', version = '0.2.*',
    dependencies = { 'nvim-lua/plenary.nvim' },
  },
  {
    'nvim-telescope/telescope-fzf-native.nvim',
    build = 'cmake -S. -Bbuild -DCMAKE_BUILD_TYPE=Release && cmake --build build --config Release && cmake --install build --prefix build',
  },
  'nvim-tree/nvim-web-devicons', -- File icons

  {
    'nvim-tree/nvim-tree.lua',
    dependencies = { 'nvim-tree/nvim-web-devicons' }, -- optional, for file icons
  },
  'smoka7/hop.nvim', -- maintained fork: phaazon/hop.nvim is gone
  'tpope/vim-repeat',
  'lewis6991/gitsigns.nvim',
  'dinhhuy258/git.nvim', -- For git blame & browse

  -- search/replace
  'thinca/vim-qfreplace',
  'wincent/ferret',

  'lukas-reineke/indent-blankline.nvim',
  'hedyhli/outline.nvim', -- maintained fork: simrat39/symbols-outline.nvim is archived
  'akinsho/toggleterm.nvim',
  'ThePrimeagen/harpoon',
  { 'folke/trouble.nvim', dependencies = { 'nvim-tree/nvim-web-devicons' } },
  'nvim-telescope/telescope-ui-select.nvim',
  'towolf/vim-helm',

  -- project management
  'nvim-telescope/telescope-project.nvim',

  'tpope/vim-surround',
  'tpope/vim-abolish',
}, {
  lockfile = vim.fn.stdpath('config') .. '/lazy-lock.json',
  change_detection = { notify = false },
})
