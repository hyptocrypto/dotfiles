-- Keymaps are automatically loaded on the VeryLazy event
-- Default keymaps that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/keymaps.lua

-- Simplify changing variable names
vim.keymap.set("n", "<leader>cn", ":let @/='\\<'.expand('<cword>').'\\>'<CR>cgn", { desc = "Change variable name" })

vim.keymap.set("n", "D", "10jzz", { desc = "Move down 10 lines and center" })
vim.keymap.set("n", "U", "10kzz", { desc = "Move up 10 lines and center" })

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

-- Only override visual mode paste to not copy when pasting over selection
vim.keymap.set("v", "p", '"_dP', { desc = "Paste without copying selection" })

-- Insert Go if-err block below cursor
local function insert_iferr()
  local lines = {
    "if err != nil {",
    "    return err",
    "}",
  }
  local row = unpack(vim.api.nvim_win_get_cursor(0))
  vim.api.nvim_buf_set_lines(0, row, row, false, lines)
end
vim.keymap.set("c", "ifer", insert_iferr, { desc = "Insert Go error handling" })

-- Toggle DAP breakpoint (or Python breakpoint() line)
local function toggle_breakpoint()
  local filetype = vim.bo.filetype
  local current_line = vim.fn.line(".")
  local indent = vim.fn.indent(current_line)

  if filetype == "python" then
    local line_content = vim.fn.getline(current_line)
    if line_content:find("breakpoint%(") == nil then
      vim.fn.append(current_line - 1, string.rep(" ", indent) .. "breakpoint()")
    else
      vim.fn.setline(current_line, line_content:gsub("breakpoint%(%s*%)", ""))
    end
  else
    require("dap").toggle_breakpoint()
  end
end
vim.keymap.set("c", "bb", toggle_breakpoint, { desc = "Toggle breakpoint" })

-- ============================================================================
-- Python Test Helpers
-- ============================================================================

local function find_nearest_pytest()
  local cursor_line = vim.fn.line(".")
  for line = cursor_line, 1, -1 do
    local test_name = vim.fn.getline(line):match("^def%s+(test_%w+)")
    if test_name then
      return test_name
    end
  end
  return nil
end

local function run_pytest_command(cmd, success_title, fail_title)
  local project_root = vim.fn.getcwd()
  local venv_path = project_root .. "/.venv"
  local timeout = 5000

  if vim.fn.filereadable(venv_path .. "/bin/activate") == 1 or vim.fn.isdirectory(venv_path) == 1 then
    cmd = venv_path .. "/bin/python -m " .. cmd
  else
    vim.notify("No .venv found in the project root!", vim.log.levels.WARN,
      { title = "Virtual Environment Warning", timeout = timeout })
    return
  end

  vim.notify("Running: " .. cmd, vim.log.levels.INFO, { title = success_title, timeout = 2000 })
  vim.system({ "sh", "-c", cmd }, { text = true }, function(result)
    vim.schedule(function()
      local output_str = result.stdout or ""
      if result.stderr and result.stderr ~= "" then
        output_str = output_str .. "\n" .. result.stderr
      end
      if result.code == 0 then
        vim.notify(output_str, vim.log.levels.INFO, { title = success_title, timeout = timeout })
      else
        vim.notify("Error running pytest:\n" .. output_str, vim.log.levels.ERROR,
          { title = fail_title, timeout = timeout })
      end
    end)
  end)
end

local function run_nearest_pytest()
  local test_name = find_nearest_pytest()
  if not test_name then
    vim.notify("No test function found near the cursor", vim.log.levels.WARN, { title = "Pytest" })
    return
  end
  run_pytest_command(string.format("pytest -v -k '%s'", test_name), "Pytest Success", "Pytest Failed")
end

local function run_all_pytests()
  run_pytest_command("pytest -v", "Pytest Success", "Pytest Failed")
end

local function debug_pytest()
  local test_name = find_nearest_pytest()
  if not test_name then
    vim.notify("No test function found near the cursor", vim.log.levels.WARN, { title = "Debug Pytest" })
    return
  end
  local cmd = string.format("startenv && pytest -v -k '%s' -s", test_name)
  require("snacks").terminal.open()
  vim.cmd("startinsert")
  vim.api.nvim_put({ cmd }, "c", true, true)
  vim.notify("Running command in terminal: " .. cmd, vim.log.levels.INFO, { title = "Debug Pytest" })
end

vim.api.nvim_create_user_command("Pytest", run_nearest_pytest, {})
vim.api.nvim_create_user_command("Pytestd", debug_pytest, {})
vim.api.nvim_create_user_command("Pytestall", run_all_pytests, {})

-- ============================================================================
-- Misc
-- ============================================================================

-- Shift+H/L to fold/unfold under cursor
vim.keymap.set("n", "<Esc>h", "zc", { desc = "Fold under cursor" })
vim.keymap.set("n", "<Esc>l", "zo", { desc = "Unfold under cursor" })

-- Disable default macro recording on `q`; use M to toggle recording into @q
vim.keymap.set("n", "q", "<Nop>")
vim.keymap.set("n", "M", function()
  if vim.fn.reg_recording() ~= "" then
    vim.cmd("normal! q")
  else
    vim.cmd("normal! qq")
  end
end, { desc = "Toggle macro recording (@q)" })
