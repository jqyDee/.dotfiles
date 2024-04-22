return {
    {
        "morhetz/gruvbox",
        priority = 1000,
        config = function()
            vim.cmd("let g:gruvbox_contrast_dark = 'hard'")
            vim.cmd("colorscheme gruvbox")
        end,
    },
    "nvim-lualine/lualine.nvim",
    {
        "nvim-telescope/telescope.nvim",
        tag = "0.1.6",
        dependencies = { "nvim-lua/plenary.nvim" }
    },
    {
        "nvim-treesitter/nvim-treesitter",
        build = ":TSUpdate"
    },
    "nvim-treesitter/playground",
    "mbbill/undotree",
    "tpope/vim-fugitive",
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
}
