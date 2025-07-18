return {
  -- colorscheme
  {
    "morhetz/gruvbox",
    branch = "master",
    commit = "f1ecde8",
    priority = 1000,
    config = function()
      vim.cmd("let g:gruvbox_contrast_dark = 'hard'")
      vim.cmd("colorscheme gruvbox")

      vim.api.nvim_set_hl(0, 'LineNrAbove', { fg='#665c54' })
      vim.api.nvim_set_hl(0, 'LineNr', { fg='#fabd2f' })
      vim.api.nvim_set_hl(0, 'LineNrBelow', { fg='#665c54' })
    end,
  },
  "nvim-lualine/lualine.nvim",

  -- telescope
  {
    'nvim-telescope/telescope.nvim',
    tag = '0.1.8',
    dependencies = { 'nvim-lua/plenary.nvim' },
    file_ignore_patterns = { "bin/**" },
  },

  -- treesitter
  "nvim-treesitter/nvim-treesitter",

  -- lsp
  "williamboman/mason.nvim",
  "williamboman/mason-lspconfig.nvim",
  {
    "VonHeikemen/lsp-zero.nvim",
    branch = "v3.x"
  },
  "neovim/nvim-lspconfig",
  "hrsh7th/cmp-nvim-lsp",
  "hrsh7th/nvim-cmp",
  "L3MON4D3/LuaSnip",

  -- markdown
  {
    "OXY2DEV/markview.nvim",
    lazy = false
  },

  -- typst
  {
  'chomosuke/typst-preview.nvim',
  lazy = false, -- or ft = 'typst'
  version = '1.*',
  opts = {}, -- lazy.nvim will implicitly calls `setup {}`
  },

  -- python
  {
    "nvimtools/none-ls.nvim",
     dependencies = { 'nvim-lua/plenary.nvim' },
  }
}
