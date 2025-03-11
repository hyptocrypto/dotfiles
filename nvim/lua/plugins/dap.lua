return {
  {
    "mfussenegger/nvim-dap",
    dependencies = {
      "rcarriga/nvim-dap-ui", -- UI for nvim-dap
      "theHamsta/nvim-dap-virtual-text", -- Virtual text for breakpoints
      "leoluz/nvim-dap-go", -- DAP for Go
      "nvim-neotest/nvim-nio", -- REQUIRED dependency for nvim-dap-ui
    },
    config = function()
      local dap = require("dap")
      local dapui = require("dapui")
      require("dap-go").setup(dapui.setup({
        layouts = {
          {
            elements = {
              { id = "scopes", size = 0.4 },
              { id = "breakpoints", size = 0.3 },
              { id = "stacks", size = 0.3 },
            },
            size = 40,
            position = "right",
          },
          {
            elements = {
              { id = "repl", size = 1 },
            },
            size = 10,
            position = "bottom",
          },
        },
      }))
      require("nvim-dap-virtual-text").setup()

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
        "<Leader>dc",
        function()
          require("dap").run({
            name = "Attach To Headless",
            type = "go",
            request = "attach",
            mode = "remote",
            host = "127.0.0.1",
            port = 2345,
          })
        end,
        desc = "Attach Buffalo Dev (DAP)",
      },
      {
        "<Leader>du",
        function()
          require("dapui").toggle()
        end,
        desc = "Toggle Debug UI",
      },
      {
        "<Leader>dC",
        function()
          require("dap").continue()
        end,
        desc = "Start/Continue Debugging",
      },
      {
        "<Leader>dn",
        function()
          require("dap").step_over()
        end,
        desc = "Step Over",
      },
      {
        "<Leader>di",
        function()
          require("dap").step_into()
        end,
        desc = "Step Into",
      },
      {
        "<Leader>do",
        function()
          require("dap").step_out()
        end,
        desc = "Step Out",
      },
      {
        "<Leader>db",
        function()
          require("dap").toggle_breakpoint()
        end,
        desc = "Toggle Breakpoint",
      },
      {
        "<Leader>du",
        function()
          require("dap").repl.open()
        end,
        desc = "Open Debug REPL",
      },
    },
  },
}
