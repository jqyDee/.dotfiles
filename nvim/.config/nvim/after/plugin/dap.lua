local dap = require("dap")
local dapui = require("dapui")

dap.adapters.codelldb = {
  type = 'server',
  port = "${port}",
  executable = {
    command = '/Users/mfischbach/.codelldb/codelldb',
    args = {"--port", "${port}"},
  }
}

dap.configurations.c = {
  {
    name = "Launch file",
    type = "codelldb",
    request = "launch",
    program = function()
      return vim.fn.input('Path to executable: ', vim.fn.getcwd() .. '/', 'file')
    end,
    cwd = '${workspaceFolder}',
    stopOnEntry = false,
  },
}

-- debugger
vim.keymap.set('n', '<F5>', dap.continue, {})
vim.keymap.set('n', '<F6>', dap.step_over, {})
vim.keymap.set('n', '<F7>', dap.step_into, {})
vim.keymap.set('n', '<F8>', dap.step_out, {})
vim.keymap.set('n', '<Leader>b', dap.toggle_breakpoint, {})
vim.keymap.set('n', '<Leader>B', dap.set_breakpoint, {})
vim.keymap.set('n', '<Leader>dl', dap.run_last, {})

-- debugger ui
dap.listeners.before.attach.dapui_config = function()
  dapui.open()
end
dap.listeners.before.launch.dapui_config = function()
  dapui.open()
end
dap.listeners.before.event_terminated.dapui_config = function()
  dapui.close()
end
dap.listeners.before.event_exited.dapui_config = function()
  dapui.close()
end
