vim.g.mapleader = " "

-- open netrw
vim.keymap.set("n", "<leader>pv", "<cmd>Ex<CR>")

-- move selected block up/down
vim.keymap.set("v", "K", ":m '<-2<CR>gv=gv")
vim.keymap.set("v", "J", ":m '>+1<CR>gv=gv")

-- keep current in buffer
vim.keymap.set("x", "<leader>p", "\"_dP")

-- yank into system clipboard
vim.keymap.set("n", "<leader>y", "\"+y")
vim.keymap.set("v", "<leader>y", "\"+y")
vim.keymap.set("n", "<leader>Y", "\"+Y")

-- delete but dont yank
vim.keymap.set("n", "<leader>d", "\"_d")
vim.keymap.set("v", "<leader>d", "\"_d")

-- load errors into quickfix list
vim.keymap.set('n', '<leader>ld', '<cmd>lua vim.diagnostic.setqflist()<CR>zz')

-- open vim diagnostic window
vim.keymap.set('n', 'gl', '<cmd>lua vim.diagnostic.open_float()<CR>zz')

-- jump to next diagnostic
vim.keymap.set('n', '<leader>k', '<cmd>lua vim.diagnostic.goto_prev()<CR>zz')
vim.keymap.set('n', '<leader>j', '<cmd>lua vim.diagnostic.goto_next()<CR>zz')

-- open quickfix window
vim.keymap.set("n", "<leader>qf", "<cmd>copen<CR>")

-- fast visual find and replace word under cursor
vim.keymap.set("n", "<leader>s", ":%s/\\<<C-r><C-w>\\>/<C-r><C-w>/gI<Left><Left><Left>")

-- netrw mark all files selected in visual mode
vim.keymap.set("x", "<leader>mf", "<cmd>norm mf<CR>")

-- format buffer
vim.keymap.set("n", "<leader>f", function()
  vim.lsp.buf.format()
end)

-- open typst preview
vim.keymap.set("n", "<leader>ot", "<cmd>TypstPreview<CR>")
