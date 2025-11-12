-- LSP-Zero base setup
local lsp_zero = require("lsp-zero")

lsp_zero.preset("recommended")
lsp_zero.set_preferences({ sign_icons = {} })

-- nvim-cmp setup
local cmp = require("cmp")
local cmp_select = { behavior = cmp.SelectBehavior.Select }
local cmp_format = lsp_zero.cmp_format({ details = true })
local cmp_mappings = lsp_zero.defaults.cmp_mappings({
  ["<S-Tab>"] = cmp.mapping.select_prev_item(cmp_select),
  ["<Tab>"]   = cmp.mapping.select_next_item(cmp_select),
  ["<CR>"]    = cmp.mapping.confirm({ select = true }),
  ["<C-space>"] = cmp.mapping.complete(),
})

cmp.setup({
  preselect = "item",
  sources = {
    { name = "nvim_lsp" },
    { name = "buffer" },
  },
  mapping = cmp_mappings,
  formatting = cmp_format,
  completion = {
    completeopt = "menu,menuone,noinsert",
  },
})

-- Common LSP keymaps
lsp_zero.on_attach(function(client, bufnr)
  local opts = { buffer = bufnr, silent = true }
  vim.keymap.set('n', 'K',  vim.lsp.buf.hover, opts)
  vim.keymap.set('n', 'gd', vim.lsp.buf.definition, opts)
  vim.keymap.set('n', 'gD', vim.lsp.buf.declaration, opts)
  vim.keymap.set('n', 'gi', vim.lsp.buf.implementation, opts)
  vim.keymap.set('n', 'go', vim.lsp.buf.type_definition, opts)
  vim.keymap.set('n', 'gr', vim.lsp.buf.references, opts)
  vim.keymap.set('n', 'gs', vim.lsp.buf.signature_help, opts)
  vim.keymap.set('n', '<F2>', vim.lsp.buf.rename, opts)
  vim.keymap.set({ 'n', 'x' }, '<F3>', function() vim.lsp.buf.format({ async = true }) end, opts)
  vim.keymap.set('n', '<F4>', vim.lsp.buf.code_action, opts)
end)

-- Mason + LSPConfig integration
require("mason").setup()
require("mason-lspconfig").setup({
  ensure_installed = {
    "clangd",
    "tinymist",
  },
  automatic_installation = true,
  handlers = {
    function(server_name)
      local opts = {}

      -- clangd custom setup
      if server_name == "clangd" then
        opts.cmd = { "clangd", "--header-insertion=never", "--suggest-missing-includes", "--compile-commands-dir=." }

      -- tinymist custom setup
      elseif server_name == "tinymist" then
        opts.settings = {
          formatterMode = "typstyle",
          semanticTokens = "disable",
        }
      end

      lsp_zero.default_setup(server_name, opts)
    end,
  },
})

