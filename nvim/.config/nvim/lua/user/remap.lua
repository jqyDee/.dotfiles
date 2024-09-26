vim.g.mapleader = " "

-- switch between .c and .h
vim.keymap.set("n", ";c", "<cmd>silent e %:p:s,.h$,.X123X,:s,.c$,.h,:s,.X123X$,.c,<CR>")
vim.keymap.set("n", ";vc", "<cmd>silent vs %:p:s,.h$,.X123X,:s,.c$,.h,:s,.X123X$,.c,<CR>")
vim.keymap.set("n", ";sc", "<cmd>silent split %:p:s,.h$,.X123X,:s,.c$,.h,:s,.X123X$,.c,<CR>")

-- open netrw
vim.keymap.set("n", "<leader>pv", vim.cmd.Ex)

-- move selected block up/down
vim.keymap.set("v", "K", ":m '<-2<CR>gv=gv")
vim.keymap.set("v", "J", ":m '>+1<CR>gv=gv")

-- keep cursor in the middle while searching
vim.keymap.set("n", "n", "nzzzv")
vim.keymap.set("n", "N", "Nzzzv")

-- keep current in buffer
vim.keymap.set("x", "<leader>p", "\"_dP")

-- yank into system clipboard
vim.keymap.set("n", "<leader>y", "\"+y")
vim.keymap.set("v", "<leader>y", "\"+y")
vim.keymap.set("n", "<leader>Y", "\"+Y")

-- delete but dont yank
vim.keymap.set("n", "<leader>d", "\"_d")
vim.keymap.set("v", "<leader>d", "\"_d")

-- open quickfix window
vim.keymap.set("n", "<leader>qf", "<cmd>copen<CR>")

-- goto next global error
vim.keymap.set("n", "<C-h>", "<cmd>cnext<CR>zz")
vim.keymap.set("n", "<C-l>", "<cmd>cprev<CR>zz")

-- goto next local error
vim.keymap.set("n", "<leader>k", "<cmd>lnext<CR>zz")
vim.keymap.set("n", "<leader>j", "<cmd>lprev<CR>zz")

-- fast visual find and replace word under cursor
vim.keymap.set("n", "<leader>s", ":%s/\\<<C-r><C-w>\\>/<C-r><C-w>/gI<Left><Left><Left>")

-- format buffer
vim.keymap.set("n", "<leader>f", function()
    vim.lsp.buf.format()
end)
