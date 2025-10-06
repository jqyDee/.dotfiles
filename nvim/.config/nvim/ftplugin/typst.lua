vim.opt_local.spell = true
vim.opt_local.spelllang = "de"

vim.opt_local.nu = false
vim.opt_local.relativenumber = false

vim.opt_local.signcolumn = 'no'

vim.opt_local.colorcolumn = ""

-- vim.opt_local.ft='rust'

vim.keymap.set("n", "<leader>tt", function()
  vim.api.nvim_put({
    "// output: TODO.pdf",
    "",
    '#import "@local/templates:0.1.0": *',
    "",
    '#show: generic.with(',
    '  title: "TODO"',
    ')'
  }, "c", true, true)
end, { desc = "Insert Typst TODO snippet" })

local function find_main_typst_file(filepath)
  local dir = vim.fn.fnamemodify(filepath, ":p:h") -- get file directory
  while dir ~= "/" do
    local main_candidate = dir .. "/main.typ"
    if vim.fn.filereadable(main_candidate) == 1 then
      return main_candidate
    end
    dir = vim.fn.fnamemodify(dir, ":h") -- go up one directory
  end
  return nil
end

local Job = require('plenary.job')

local function get_output_file(main_file)
  local f = io.open(main_file, "r")
  if not f then return nil end
  local first_line = f:read("*l")
  f:close()
  if first_line then
    return first_line:match("^//%s*output:%s*(.+)$")
  end
  return nil
end

local function compile_typst_async(main_file)
  local output_file = get_output_file(main_file)
  local main_dir = vim.fn.fnamemodify(main_file, ":p:h") -- directory of main.typ

  if output_file then
    -- Make output path relative to main_dir
    output_file = main_dir .. "/" .. output_file
  end

  local args = {"compile", main_file}
  if output_file then
    table.insert(args, output_file)
  end

  Job:new({
    command = "typst",
    args = args,
    on_exit = function(j, return_val)
      vim.schedule(function()
        if return_val == 0 then
          vim.notify("✅ Typst compiled successfully: " .. main_file)
        else
          local err = table.concat(j:stderr_result(), "\n")
          vim.notify("❌ Typst compilation failed:\n" .. err, vim.log.levels.ERROR)
        end
      end)
    end,
  }):start()
end

vim.api.nvim_create_autocmd({"BufWritePost", "BufDelete", "BufUnload"}, {
  pattern = {"*.typ"},
  callback = function(args)
    local buf_path = vim.fn.expand("<afile>")
    local main_file = find_main_typst_file(buf_path)
    if main_file then
      compile_typst_async(main_file)
    end
  end,
})

