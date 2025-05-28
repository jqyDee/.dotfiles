local augroup = vim.api.nvim_create_augroup("LspFormatting", { clear = true })

local null_ls = require("null-ls")

null_ls.setup({
  sources = {
    null_ls.builtins.formatting.black,
  },
  on_attach = function(client, bufnr)
    local filetype = vim.api.nvim_buf_get_option(bufnr, "filetype")
    if client.supports_method("textDocument/formatting") and filetype == "python" then
      vim.api.nvim_clear_autocmds({ group = augroup, buffer = bufnr })
      vim.api.nvim_create_autocmd("BufWritePre", {
        group = augroup,
        buffer = bufnr,
        callback = function()
          vim.lsp.buf.format({ bufnr = bufnr })
        end,
      })
    end
  end,
})

