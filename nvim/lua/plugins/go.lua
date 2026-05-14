return {
  "ray-x/go.nvim",
  dependencies = {
    "ray-x/guihua.lua",
    "neovim/nvim-lspconfig",
    "nvim-treesitter/nvim-treesitter",
    "mfussenegger/nvim-dap",
  },
  ft = { "go", "gomod" },
  build = ':lua require("go.install").update_all_sync()',
  config = function()
    require("go").setup()

    -- ============================================================================
    -- Go Test Helpers
    -- ============================================================================

    local function extract_go_test_name(line)
      return line:match("^func%s+(Test[%w_]*)")
    end

    local function find_nearest_go_test()
      local cursor_line = vim.fn.line(".")
      for line = cursor_line, 1, -1 do
        local test_func = extract_go_test_name(vim.fn.getline(line))
        if test_func then
          return test_func
        end
      end
      return nil
    end

    local function extract_all_go_tests()
      local test_functions = {}
      for _, line in ipairs(vim.api.nvim_buf_get_lines(0, 0, -1, false)) do
        local test_func = extract_go_test_name(line)
        if test_func then
          table.insert(test_functions, test_func)
        end
      end
      return test_functions
    end

    local function build_go_test_pattern(test_functions)
      if #test_functions == 1 then
        return "^" .. test_functions[1] .. "$"
      else
        return "^(" .. table.concat(test_functions, "|") .. ")$"
      end
    end

    local function run_go_test_command(cmd, success_title, fail_title)
      local file_dir = vim.fn.expand("%:p:h")
      local timeout = 5000
      vim.notify("Running: " .. cmd, vim.log.levels.INFO, { title = "Go Test", timeout = 2000 })
      vim.system({ "sh", "-c", "cd " .. file_dir .. " && " .. cmd }, { text = true }, function(result)
        vim.schedule(function()
          local output_str = result.stdout or ""
          if result.stderr and result.stderr ~= "" then
            output_str = output_str .. "\n" .. result.stderr
          end
          if result.code == 0 then
            vim.notify(output_str, vim.log.levels.INFO, { title = success_title, timeout = timeout })
          else
            vim.notify("Error running go test:\n" .. output_str, vim.log.levels.ERROR,
              { title = fail_title, timeout = timeout })
          end
        end)
      end)
    end

    local function run_nearest_go_test()
      local test_func = find_nearest_go_test()
      if not test_func then
        vim.notify("No test function found near the cursor", vim.log.levels.WARN, { title = "Go Test" })
        return
      end
      run_go_test_command("go test -v -run " .. build_go_test_pattern({ test_func }),
        "Go Test Success", "Go Test Failed")
    end

    local function run_go_tests_in_file()
      local test_functions = extract_all_go_tests()
      if #test_functions == 0 then
        vim.notify("No test functions found in current file", vim.log.levels.WARN, { title = "Go Test" })
        return
      end
      run_go_test_command("go test -v -run '" .. build_go_test_pattern(test_functions) .. "'",
        "Go Test Success", "Go Test Failed")
    end

    local function run_go_tests_in_package()
      run_go_test_command("go test -v", "Go Test Success", "Go Test Failed")
    end

    local function debug_go_test()
      local test_func = find_nearest_go_test()
      if not test_func then
        vim.notify("No test function found near the cursor", vim.log.levels.WARN, { title = "Debug Go Test" })
        return
      end
      require("dap").run({
        type = "go",
        name = "Debug Test: " .. test_func,
        request = "launch",
        mode = "test",
        program = vim.fn.expand("%:p:h"),
        args = { "-test.run", build_go_test_pattern({ test_func }) },
      })
      vim.notify("Debugging test: " .. test_func, vim.log.levels.INFO, { title = "Debug Go Test" })
    end

    vim.api.nvim_create_user_command("Gotest", run_nearest_go_test, {})
    vim.api.nvim_create_user_command("Gotestall", run_go_tests_in_file, {})
    vim.api.nvim_create_user_command("Gotestpackage", run_go_tests_in_package, {})
    vim.api.nvim_create_user_command("GoDebugTest", debug_go_test, {})
    vim.keymap.set("n", "<leader>dt", debug_go_test, { desc = "Go Debug Test" })
  end,
}
