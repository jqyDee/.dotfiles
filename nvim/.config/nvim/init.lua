-- no remote plugins in use; skip slow provider probing (python3 via pyenv shims)
vim.g.loaded_node_provider = 0
vim.g.loaded_perl_provider = 0
vim.g.loaded_python3_provider = 0
vim.g.loaded_ruby_provider = 0

require("plugins")
require("user")

require("lazy").setup("plugins.plugins")
