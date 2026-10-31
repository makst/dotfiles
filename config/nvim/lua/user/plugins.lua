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
  'tinted-theming/tinted-vim',
  'nvim-lua/plenary.nvim', -- Common utilities

  -- 'navarasu/onedark.nvim',
  -- completion, signature help and snippets (nvim's own vim.snippet); 1.* ships a prebuilt fuzzy matcher
  { 'saghen/blink.cmp', version = '1.*' },
  'stevearc/conform.nvim', -- format on save with the project's formatters, the language server as fallback

  -- status line
  'nvim-lualine/lualine.nvim',

  -- LSP
  'mason-org/mason.nvim',
  'mason-org/mason-lspconfig.nvim',
  'neovim/nvim-lspconfig',

  'rafamadriz/friendly-snippets', -- snippets for blink.cmp
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
  'stevearc/oil.nvim', -- a directory as an editable buffer: rename, move, delete files by editing text
  'folke/flash.nvim', -- jump to any visible position with labels
  'tpope/vim-repeat',
  'lewis6991/gitsigns.nvim',
  'dinhhuy258/git.nvim', -- For git blame & browse

  'MagicDuck/grug-far.nvim', -- search and replace across files

  'lukas-reineke/indent-blankline.nvim',
  'hedyhli/outline.nvim', -- maintained fork: simrat39/symbols-outline.nvim is archived
  'akinsho/toggleterm.nvim',
  'christoomey/vim-tmux-navigator', -- CTRL-H/J/K/L move across nvim splits and tmux panes
  { 'ThePrimeagen/harpoon', branch = 'harpoon2', dependencies = { 'nvim-lua/plenary.nvim' } },
  { 'folke/trouble.nvim', dependencies = { 'nvim-tree/nvim-web-devicons' } },
  'nvim-telescope/telescope-ui-select.nvim',
  'towolf/vim-helm',

  -- project management
  'nvim-telescope/telescope-project.nvim',

  'kylechui/nvim-surround',
  'tpope/vim-abolish',
}, {
  lockfile = vim.fn.stdpath('config') .. '/lazy-lock.json',
  change_detection = { notify = false },
})
