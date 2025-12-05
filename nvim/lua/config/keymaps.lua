-- Keymaps are automatically loaded on the VeryLazy event
-- Default keymaps that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/keymaps.lua
-- Add any additional keymaps here

-- Simplify changing variable names
vim.keymap.set("n", "<leader>cn", ":let @/='\\<'.expand('<cword>').'\\>'<CR>cgn", { desc = "Change variable name" })

vim.keymap.set("n", "D", "10jzz", { desc = "Move down 10 lines and center" })
vim.keymap.set("n", "U", "10kzz", { desc = "Move up 10 lines and center" })

-- Make backspace behave and wrap on newlines
vim.opt.backspace = { "eol", "start", "indent" }
vim.opt.whichwrap:append("<,>,h,l")

-- Map Tab to indent in normal, visual, and select modes
vim.keymap.set("n", "<Tab>", ">>", { desc = "Indent line" })
vim.keymap.set("v", "<Tab>", ">gv", { desc = "Indent selection" })
vim.keymap.set("s", "<Tab>", ">", { desc = "Indent selection" })

-- Map Shift+Tab to unindent in normal, visual, and select modes
vim.keymap.set("n", "<S-Tab>", "<<", { desc = "Unindent line" })
vim.keymap.set("v", "<S-Tab>", "<gv", { desc = "Unindent selection" })
vim.keymap.set("s", "<S-Tab>", "<", { desc = "Unindent selection" })

-- Personal keymaps
vim.keymap.set("i", "jk", "<Esc>", { desc = "Exit insert mode" })
vim.keymap.set("n", "r", "<C-r>", { desc = "Redo" })

-- Delete operations that don't overwrite clipboard
-- vim.keymap.set("n", "dd", '"_dd', { desc = "Delete line without copying" })

-- Keep normal paste behavior (don't override p/P)
-- Only override visual mode paste to not copy when pasting over selection
vim.keymap.set("v", "p", '"_dP', { desc = "Paste without copying selection" })

function Insert_iferr()
  local lines = {
    "if err != nil {",
    "    return err",
    "}",
  }
  local row, col = unpack(vim.api.nvim_win_get_cursor(0)) -- Get the current cursor position
  vim.api.nvim_buf_set_lines(0, row, row, false, lines) -- Insert the lines below the cursor
end
vim.keymap.set("c", "ifer", ":lua Insert_iferr()<CR>", { desc = "Insert Go error handling" })

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
    require("dap").toggle_breakpoint()
  end
end

local function run_go_test_command(cmd, success_title, fail_title)
  -- Run the command in the current file's directory
  local file_dir = vim.fn.expand("%:p:h") -- Get the directory of the current file
  local timeout = 5000

  -- Notify that the test is starting
  vim.notify("Running: " .. cmd, vim.log.levels.INFO, { title = "Go Test", timeout = 2000 })

  -- Run the command asynchronously
  vim.system({ "sh", "-c", "cd " .. file_dir .. " && " .. cmd }, { text = true }, function(result)
    vim.schedule(function()
      local output_str = result.stdout or ""
      if result.stderr and result.stderr ~= "" then
        output_str = output_str .. "\n" .. result.stderr
      end

      if result.code == 0 then
        vim.notify(output_str, vim.log.levels.INFO, { title = success_title, timeout = timeout })
      else
        vim.notify(
          "Error running go test:\n" .. output_str,
          vim.log.levels.ERROR,
          { title = fail_title, timeout = timeout }
        )
      end
    end)
  end)
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
  local test_func = line:match("^func%s+(Test[%w_]*)")
  if not test_func then
    vim.notify("Failed to parse test function name", vim.log.levels.ERROR, { title = "Go Test" })
    return
  end

  -- Build and run the `go test` command
  local cmd = "go test -v -run ^" .. test_func .. "$"
  run_go_test_command(cmd, "Go Test Success", "Go Test Failed")
end

-- Function to run all Go tests in the current file
local function run_go_tests_in_file()
  local test_functions = {}
  local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)
  
  -- Extract all test function names from the current file
  for _, line in ipairs(lines) do
    local test_func = line:match("^func%s+(Test[%w_]*)")
    if test_func then
      table.insert(test_functions, test_func)
    end
  end
  
  if #test_functions == 0 then
    vim.notify("No test functions found in current file", vim.log.levels.WARN, { title = "Go Test" })
    return
  end
  
  -- Build a regex pattern that matches any of the test functions in this file
  -- Format: ^(TestFunc1|TestFunc2|TestFunc3)$
  -- Quote the pattern to prevent shell interpretation of special characters
  local pattern = "^(" .. table.concat(test_functions, "|") .. ")$"
  local cmd = "go test -v -run '" .. pattern .. "'"
  run_go_test_command(cmd, "Go Test Success", "Go Test Failed")
end

-- Function to run all Go tests in the package
local function run_go_tests_in_package()
  local cmd = "go test -v"
  run_go_test_command(cmd, "Go Test Success", "Go Test Failed")
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
vim.keymap.set("c", "bb", ":lua ToggleBreakpoint()<CR>:<Esc>", { desc = "Toggle breakpoint" })

vim.api.nvim_create_user_command("Pytest", run_nearest_pytest, {})
vim.api.nvim_create_user_command("Pytestd", debug_pytest, {})
vim.api.nvim_create_user_command("Pytestall", run_all_pytests, {})

vim.api.nvim_create_user_command("Gotest", run_nearest_go_test, {})
vim.api.nvim_create_user_command("Gotestall", run_go_tests_in_file, {})
vim.api.nvim_create_user_command("Gotestpackage", run_go_tests_in_package, {})

-- Shift+H to fold under cursor
vim.keymap.set("n", "H", "zc", { desc = "Fold under cursor" })

-- Shift+L to unfold under cursor
vim.keymap.set("n", "L", "zo", { desc = "Unfold under cursor" })

-- Disable default macro recording on `q`
vim.keymap.set("n", "q", "<Nop>")

-- Toggle recording macro @q with Shift-M
vim.keymap.set("n", "M", function()
  if vim.fn.reg_recording() ~= "" then
    -- currently recording → stop
    vim.cmd("normal! q")
  else
    -- not recording → start recording into register q
    vim.cmd("normal! qq")
  end
end, { desc = "Toggle macro recording (@q)" })
