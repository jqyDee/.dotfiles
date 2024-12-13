local builtin = require('telescope.builtin')
vim.keymap.set('n', '<leader>fr', builtin.resume, { desc = 'Telescope find files' })

vim.keymap.set('n', '<leader>ff', builtin.find_files, { desc = 'Telescope find files' })
vim.keymap.set('n', '<leader>fg', builtin.live_grep, { desc = 'Telescope live grep' })
vim.keymap.set('n', '<leader>fb', builtin.buffers, { desc = 'Telescope buffers' })
vim.keymap.set('n', '<leader>ma', builtin.man_pages, { desc = 'Telescope buffers' })
