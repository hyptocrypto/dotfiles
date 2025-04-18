return {
  {
    "mfussenegger/nvim-dap",
    dependencies = {
      "rcarriga/nvim-dap-ui",
      "leoluz/nvim-dap-go",
      "nvim-neotest/nvim-nio",
    },
    config = function()
      local dap = require("dap")
      local dapui = require("dapui")
      require("dap-go").setup()

      dapui.setup({
        layouts = {
          {
            elements = {
              { id = "stacks", size = 0.3 },
              { id = "breakpoints", size = 0.3 },
            },
            size = 30,
            position = "left",
          },
          {
            elements = {
              { id = "scopes", size = 1 },
            },
            size = 10,
            position = "bottom",
          },
        },
      })

      -- Clean up duplicate configs
      local unique_configs = {}
      local seen = {}

      for _, config in ipairs(dap.configurations.go or {}) do
        if not seen[config.name] then
          table.insert(unique_configs, config)
          seen[config.name] = true
        end
      end

      -- Add custom headless attach config
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
        local ok, neotree = pcall(require, "neo-tree.command")
        if ok then
          neotree.execute({ action = "close" })
        end
        dapui.open()
      end
      dap.listeners.before.event_terminated["dapui_config"] = function()
        dapui.close()
      end
      dap.listeners.before.event_exited["dapui_config"] = function()
        dapui.close()
      end
      dap.listeners.after.event_stopped["dapui_config"] = function()
        dapui.open()
      end
    end,

    keys = function()
      local dap = require("dap")
      local dap_go = require("dap-go")
      return {
        {
          "<Leader>du",
          function()
            require("dapui").toggle({ reset = true })
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
          "<Leader>dC",
          function()
            dap.clear_breakpoints()
          end,
          desc = "Clear breakpoints",
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
            dap_go.debug_test()
          end,
          desc = "Debug test",
        },
      }
    end,
  },
}
