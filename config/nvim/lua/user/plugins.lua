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
  'neovim/nvim-lspconfig',

  'rafamadriz/friendly-snippets', -- snippets for blink.cmp
  { 'nvim-treesitter/nvim-treesitter', build = ':TSUpdate' },
  'aaronik/treewalker.nvim', -- replaces tree-climber, which needs the removed nvim-treesitter APIs
  'windwp/nvim-autopairs',
  'windwp/nvim-ts-autotag',
  'hashivim/vim-terraform',

  -- every picker (;f, ;r, …, vim.ui.select): runs the real fzf, with config/fzf/fzfrc's look (user/fzf-lua)
  'ibhagwan/fzf-lua',
  'nvim-tree/nvim-web-devicons', -- File icons

  {
    'nvim-tree/nvim-tree.lua',
    dependencies = { 'nvim-tree/nvim-web-devicons' }, -- optional, for file icons
  },
  'folke/flash.nvim', -- jump to any visible position with labels
  'tpope/vim-repeat',
  'lewis6991/gitsigns.nvim',
  'dinhhuy258/git.nvim', -- For git blame & browse

  'MagicDuck/grug-far.nvim', -- search and replace across files

  'lukas-reineke/indent-blankline.nvim',
  'hedyhli/outline.nvim', -- maintained fork: simrat39/symbols-outline.nvim is archived
  'akinsho/toggleterm.nvim', -- the Gradle and logcat terminals (user/android); other shells are tmux popups (user/tmux)
  'christoomey/vim-tmux-navigator', -- CTRL-H/J/K/L move across nvim splits and tmux panes
  { 'ThePrimeagen/harpoon', branch = 'harpoon2', dependencies = { 'nvim-lua/plenary.nvim' } },
  { 'folke/trouble.nvim', dependencies = { 'nvim-tree/nvim-web-devicons' } },
  'towolf/vim-helm',
  'roeeyn/codetour.nvim', -- code tours: ordered, annotated stops walked with the quickfix list (user/codetour)

  'kylechui/nvim-surround',
  'tpope/vim-abolish',

  -- iOS: build, run and test Xcode projects (user/xcodebuild)
  { 'wojciech-kulik/xcodebuild.nvim', dependencies = { 'MunifTanjim/nui.nvim', 'ibhagwan/fzf-lua' } },
}, {
  lockfile = vim.fn.stdpath('config') .. '/lazy-lock.json',
  change_detection = { notify = false },
})
