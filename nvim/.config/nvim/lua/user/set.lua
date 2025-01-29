vim.opt.nu = true
vim.opt.relativenumber = true

vim.opt.splitright = true

vim.opt.breakindent = true

vim.opt.tabstop = 2
vim.opt.softtabstop = 2
vim.opt.shiftwidth = 2
vim.opt.smartindent = true
vim.opt.expandtab = false

vim.opt.wrap = true

vim.opt.signcolumn = 'yes'

vim.opt.list = true
vim.opt.listchars = { tab = '»·', trail = '·', lead = "·" }

-- find recursively
vim.opt.path:append "**"

vim.opt.swapfile = false
vim.opt.backup = false
vim.opt.undodir = os.getenv("HOME") .. "/.vim/undodir"
vim.opt.undofile = true

vim.opt.hlsearch = true
vim.opt.incsearch = true
vim.opt.inccommand = 'split'

vim.opt.scrolloff = 10

vim.opt.updatetime = 250
vim.opt.timeoutlen = 300

-- line number color
vim.api.nvim_set_hl(0, 'LineNrAbove', { fg='orange' })
vim.api.nvim_set_hl(0, 'LineNr', { fg='orange' })
vim.api.nvim_set_hl(0, 'LineNrBelow', { fg='orange' })

vim.opt.colorcolumn = "80"

vim.g.mapleader = " "
