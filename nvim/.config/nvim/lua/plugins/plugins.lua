return {
  -- colorscheme
  {
    "morhetz/gruvbox",
    priority = 1000,
    config = function()
      vim.cmd("let g:gruvbox_contrast_dark = 'hard'")
      vim.cmd("colorscheme gruvbox")
    end,
  },
  "nvim-lualine/lualine.nvim",

  -- telescope
  {
    'nvim-telescope/telescope.nvim',
    tag = '0.1.8',
    dependencies = { 'nvim-lua/plenary.nvim' }
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

  -- debugger
  {
    "rcarriga/nvim-dap-ui",
    dependencies = {
      "mfussenegger/nvim-dap",
      "nvim-neotest/nvim-nio",
    },
  },
}
