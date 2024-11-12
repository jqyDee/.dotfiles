local lsp = require("lsp-zero")

lsp.preset("recommended")
lsp.set_preferences({ sign_icons = {} })

local cmp = require("cmp")
local cmp_select = { behavior = cmp.SelectBehavior.Select }
local cmp_format = require('lsp-zero').cmp_format({ details = true })
local cmp_mappings = lsp.defaults.cmp_mappings({
    ["<S-Tab>"] = cmp.mapping.select_prev_item(cmp_select),
    ["<Tab>"] = cmp.mapping.select_next_item(cmp_select),
    ["<CR>"] = cmp.mapping.confirm({ select = true }),
    ["<C-space>"] = cmp.mapping.complete(),
})

cmp.setup({
    preselect = "item",
    sources = {
        { name = "nvim_lsp" },
        { name = "buffer" },
    },
    completion = {
        completeopt = "menu,menuone,noinsert"
    },
    mapping = cmp_mappings,
    formatting = cmp_format,
})

lsp.on_attach(function(client, bufnr)
    vim.keymap.set('n', 'K', '<cmd>lua vim.lsp.buf.hover()<cr>', opts)
    vim.keymap.set('n', 'gd', '<cmd>lua vim.lsp.buf.definition()<cr>', opts)
    vim.keymap.set('n', 'gD', '<cmd>lua vim.lsp.buf.declaration()<cr>', opts)
    vim.keymap.set('n', 'gi', '<cmd>lua vim.lsp.buf.implementation()<cr>', opts)
    vim.keymap.set('n', 'go', '<cmd>lua vim.lsp.buf.type_definition()<cr>', opts)
    vim.keymap.set('n', 'gr', '<cmd>lua vim.lsp.buf.references()<cr>', opts)
    vim.keymap.set('n', 'gs', '<cmd>lua vim.lsp.buf.signature_help()<cr>', opts)
    vim.keymap.set('n', '<F2>', '<cmd>lua vim.lsp.buf.rename()<cr>', opts)
    vim.keymap.set({ 'n', 'x' }, '<F3>', '<cmd>lua vim.lsp.buf.format({async = true})<cr>', opts)
    vim.keymap.set('n', '<F4>', '<cmd>lua vim.lsp.buf.code_action()<cr>', opts)
end)

require("mason").setup({})
require("mason-lspconfig").setup({
    ensure_installed = {
    },
    handlers = {
        lsp.default_setup,
    },
})
