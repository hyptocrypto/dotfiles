local dap = require("dap")
return {
  {
    "mfussenegger/nvim-dap",
    dependencies = {
      "rcarriga/nvim-dap-ui",
      "leoluz/nvim-dap-go",
      "nvim-neotest/nvim-nio",
    },
    config = function()
      local dapui = require("dapui")
      require("dap-go").setup(dapui.setup({
        layouts = {
          {
            elements = {
              { id = "breakpoints", size = 0.3 },
              { id = "stacks", size = 0.3 },
            },
            size = 30,
            position = "right",
          },
          {
            elements = {
              { id = "repl", size = 0.5 },
              { id = "scopes", size = 0.5 },
            },
            size = 10,
            position = "bottom",
          },
        },
      }))
      -- Remove duplicates by keeping only unique names
      local unique_configs = {}
      local seen = {}

      for _, config in ipairs(dap.configurations.go or {}) do
        if not seen[config.name] then
          table.insert(unique_configs, config)
          seen[config.name] = true
        end
      end

      -- Add the custom "Attach To Headless" config
      table.insert(unique_configs, 1, {
        name = "Attach To Headless (127.0.0.1:2345)",
        type = "go",
        request = "attach",
        mode = "remote",
        host = "127.0.0.1",
        port = 2345,
      })

      dap.configurations.go = unique_configs
      -- Auto open/close UI when debugging starts/stops
      dap.listeners.after.event_initialized["dapui_config"] = function()
        dapui.open()
      end
      dap.listeners.before.event_terminated["dapui_config"] = function()
        dapui.close()
      end
      dap.listeners.before.event_exited["dapui_config"] = function()
        dapui.close()
      end
    end,

    keys = {
      {
        "<Leader>du",
        function()
          require("dapui").toggle({ rest = true })
        end,
        desc = "Toggle Debug UI",
      },
      {
        "<Leader>dc",
        function()
          dap.continue()
        end,
        desc = "Start/Continue Debugging",
      },
      {
        "<Leader>dn",
        function()
          dap.step_over()
        end,
        desc = "Step Over",
      },
      {
        "<Leader>di",
        function()
          dap.step_into()
        end,
        desc = "Step Into",
      },
      {
        "<Leader>do",
        function()
          dap.step_out()
        end,
        desc = "Step Out",
      },
      {
        "<Leader>db",
        function()
          dap.toggle_breakpoint()
        end,
        desc = "Toggle Breakpoint",
      },
      {
        "<Leader>df",
        function()
          dap.focus_frame()
        end,
        desc = "Focus",
      },
      {
        "<Leader>dt",
        function()
          require("dap-go").debug_test()
        end,
        desc = "Debug test",
      },
    },
  },
}
