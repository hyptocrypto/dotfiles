-- Keymaps are automatically loaded on the VeryLazy event
-- Default keymaps that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/keymaps.lua
-- Add any additional keymaps here

local dap = require("dap")
local dap_go = require("dap-go")

-- Function to toggle between the current buffer and Neo-tree
function ToggleNeoTreeOrCode()
  local neotree_winid = nil
  local code_winid = nil

  -- Iterate through windows to find Neo-tree and a code file
  for winnr = 1, vim.fn.winnr("$") do
    local bufnr = vim.fn.winbufnr(winnr)
    local buftype = vim.bo[bufnr].buftype
    local filetype = vim.bo[bufnr].filetype

    if filetype == "neo-tree" then
      neotree_winid = winnr
    elseif buftype == "" then
      code_winid = winnr
    end
  end

  if neotree_winid then
    -- If currently in Neo-tree, switch to the code file
    if vim.fn.winnr() == neotree_winid then
      if code_winid then
        vim.cmd(code_winid .. "wincmd w")
      end
    else
      -- Otherwise, switch to Neo-tree
      vim.cmd(neotree_winid .. "wincmd w")
    end
  else
    -- If Neo-tree is not open, focus the first code file window
    if code_winid then
      vim.cmd(code_winid .. "wincmd w")
    end
  end
end

vim.keymap.set("n", "<leader>t", ToggleNeoTreeOrCode, { desc = "Toggle between Neo-tree and code file" })

-- Simplify changing variable names
vim.api.nvim_set_keymap(
  "n",
  "<leader>cn",
  ":let @/='\\<'.expand('<cword>').'\\>'<CR>cgn",
  { noremap = true, silent = true }
)

-- Make backspace behave and wrap on newlines
vim.opt.backspace = { "eol", "start", "indent" }
vim.opt.whichwrap:append("<,>,h,l")

-- Map Tab to indent in normal, visual, and select modes
vim.api.nvim_set_keymap("n", "<Tab>", ">>", { noremap = true })
vim.api.nvim_set_keymap("v", "<Tab>", ">gv", { noremap = true })
vim.api.nvim_set_keymap("s", "<Tab>", ">", { noremap = true })

-- Map Shift+Tab to unindent in normal, visual, and select modes
vim.api.nvim_set_keymap("n", "<S-Tab>", "<<", { noremap = true })
vim.api.nvim_set_keymap("v", "<S-Tab>", "<gv", { noremap = true })
vim.api.nvim_set_keymap("s", "<S-Tab>", "<", { noremap = true })

-- Personal
vim.api.nvim_set_keymap("i", "jk", "<Esc>", { noremap = true, silent = true })
vim.api.nvim_set_keymap("n", "r", "<C-r>", { noremap = true, silent = true })
--- Dont copy to reg when pasting
vim.api.nvim_set_keymap("v", "p", '"_dP', { noremap = true, silent = true })

function Insert_iferr()
  local lines = {
    "if err != nil {",
    "    return err",
    "}",
  }
  local row, col = unpack(vim.api.nvim_win_get_cursor(0)) -- Get the current cursor position
  vim.api.nvim_buf_set_lines(0, row, row, false, lines) -- Insert the lines below the cursor
end
vim.api.nvim_set_keymap("c", "ifer", ":lua Insert_iferr()<CR>", { noremap = true, silent = true })

function ToggleBreakpoint()
  local filetype = vim.bo.filetype
  local current_line = vim.fn.line(".")
  local indent = vim.fn.indent(current_line)

  if filetype == "python" then
    -- Insert `breakpoint()` at the current line, maintaining indentation
    local line_content = vim.fn.getline(current_line)

    if line_content:find("breakpoint%(") == nil then
      -- Add `breakpoint()` without removing existing content
      local new_line = string.rep(" ", indent) .. "breakpoint()"
      vim.fn.append(current_line - 1, new_line)
    else
      -- If `breakpoint()` already exists, remove it
      vim.fn.setline(current_line, line_content:gsub("breakpoint%(%s*%)", ""))
    end
  else
    -- Toggle Dap breakpoint
    dap.toggle_breakpoint()
  end
end

local function run_go_test_command(cmd, success_title, fail_title)
  -- Run the command in the current file's directory
  local file_dir = vim.fn.expand("%:p:h") -- Get the directory of the current file
  local output = vim.fn.systemlist("cd " .. file_dir .. " && " .. cmd)
  local output_str = table.concat(output, "\n")
  local timeout = 10000

  if vim.v.shell_error == 0 then
    vim.notify(output_str, vim.log.levels.INFO, { title = success_title, timeout = timeout })
  else
    vim.notify(
      "Error running go test:\n" .. output_str,
      vim.log.levels.ERROR,
      { title = fail_title, timeout = timeout }
    )
  end
end

-- Function to run the nearest Go test under the cursor
local function run_nearest_go_test()
  -- Get the test name under the cursor
  local test_name = vim.fn.search("^func Test", "bnW")
  if test_name == 0 then
    vim.notify("No test function found near the cursor", vim.log.levels.WARN, { title = "Go Test" })
    return
  end

  -- Extract the name of the test function
  local line = vim.fn.getline(test_name)
  local test_func = line:match("^func%s+(Test%w+)")
  if not test_func then
    vim.notify("Failed to parse test function name", vim.log.levels.ERROR, { title = "Go Test" })
    return
  end

  -- Build and run the `go test` command
  local cmd = "go test -v -run " .. test_func
  run_go_test_command(cmd, "Go Test Success", "Go Test Failed")
end

-- Function to run all Go tests in the current file
local function run_go_tests()
  local cmd = "go test -v"
  run_go_test_command(cmd, "Go Test Success", "Go Test Failed")
end

local function debug_go_test()
  dap_go.debug_test()
end

local function run_pytest_command(cmd, success_title, fail_title)
  -- Find the root of the project
  local project_root = vim.fn.getcwd()
  local venv_path = project_root .. "/.venv/bin/activate"
  local timeout = 5000

  -- Check if .venv exists
  if vim.fn.filereadable(venv_path) == 1 or vim.fn.isdirectory(project_root .. "/.venv") == 1 then
    -- Prepend the .venv Python binary to the command
    local python_bin = project_root .. "/.venv/bin/python"
    cmd = python_bin .. " -m " .. cmd
  else
    vim.notify(
      "No .venv found in the project root!",
      vim.log.levels.WARN,
      { title = "Virtual Environment Warning", timeout = timeout }
    )
    return
  end

  -- Run the command
  local output = vim.fn.systemlist(cmd)
  local output_str = table.concat(output, "\n")

  -- Check the result and notify
  if vim.v.shell_error == 0 then
    vim.notify(output_str, vim.log.levels.INFO, { title = success_title, timeout = timeout })
  else
    vim.notify("Error running pytest:\n" .. output_str, vim.log.levels.ERROR, { title = fail_title, timeout = timeout })
  end
end

local function run_nearest_pytest()
  -- Search backward from the cursor to find the nearest test function
  local cursor_line = vim.fn.line(".")
  local test_name = nil

  -- Search backward for a function definition starting with "test_"
  for line = cursor_line, 1, -1 do
    local current_line = vim.fn.getline(line)
    test_name = current_line:match("^def%s+(test_%w+)")
    if test_name then
      break
    end
  end

  -- If no test name is found, notify the user
  if not test_name then
    vim.notify("No test function found near the cursor", vim.log.levels.WARN, { title = "Pytest" })
    return
  end

  -- Build the pytest command to run the specific test
  local cmd = string.format("pytest -v -k '%s'", test_name)
  run_pytest_command(cmd, "Pytest Success", "Pytest Failed")
end

local function run_all_pytests()
  local cmd = "pytest -v"
  run_pytest_command(cmd, "Pytest Success", "Pytest Failed")
end

local function debug_pytest()
  -- Get the nearest test name under the cursor
  local cursor_line = vim.fn.line(".")
  local test_name = nil

  -- Search backward for the nearest test function starting with "test_"
  for line = cursor_line, 1, -1 do
    local current_line = vim.fn.getline(line)
    test_name = current_line:match("^def%s+(test_%w+)")
    if test_name then
      break
    end
  end

  if not test_name then
    vim.notify("No test function found near the cursor", vim.log.levels.WARN, { title = "Debug Pytest" })
    return
  end

  -- Build the pytest command
  local cmd = string.format("startenv && pytest -v -k '%s' -s", test_name)

  -- Open the terminal with snacks
  require("snacks").terminal.open()
  vim.cmd("startinsert") -- Ensure insert mode is active in the terminal
  vim.api.nvim_put({ cmd }, "c", true, true)
  vim.notify("Running command in terminal: " .. cmd, vim.log.levels.INFO, { title = "Debug Pytest" })
end

-- Create a command to trigger the function
vim.api.nvim_set_keymap("c", "bb", ":lua ToggleBreakpoint()<CR>:<Esc>", { noremap = true, silent = true })

vim.api.nvim_create_user_command("Pytest", run_nearest_pytest, {})
vim.api.nvim_create_user_command("Pytestd", debug_pytest, {})
vim.api.nvim_create_user_command("Pytestall", run_all_pytests, {})

vim.api.nvim_create_user_command("Gotest", run_nearest_go_test, {})
vim.api.nvim_create_user_command("Gotestd", debug_go_test, {})
vim.api.nvim_create_user_command("Gotestall", run_go_tests, {})
vim.keymap.set("c", "Codelens", "lua vim.lsp.codelens.run()", { desc = "Run CodeLens" })
