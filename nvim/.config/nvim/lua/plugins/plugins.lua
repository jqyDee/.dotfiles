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
}
