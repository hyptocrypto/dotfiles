local function close_neotree()
  for _, win in ipairs(vim.api.nvim_list_wins()) do
    local buf = vim.api.nvim_win_get_buf(win)
    if vim.bo[buf].filetype == "neo-tree" then
      vim.cmd("Neotree close")
      return
    end
  end
end

return {
  {
    "igorlfs/nvim-dap-view",
    lazy = false,
    opts = {
      winbar = {
        sections = { "watches", "scopes", "breakpoints", "threads", "repl" },
        default_section = "scopes",
        controls = {
          enabled = true,
          position = "right",
        },
      },
      windows = {
        position = "right",
        size = 0.5,
        terminal = {
          hide = { "go" },
        },
      },
      auto_toggle = false,
    },
  },
  {
    "mfussenegger/nvim-dap",
    event = "VeryLazy",
    dependencies = {
      "igorlfs/nvim-dap-view",
      "leoluz/nvim-dap-go",
    },
    config = function()
      local dap = require("dap")
      local dapview = require("dap-view")
      require("dap-go").setup()

      local unique_configs = {}
      local seen = {}

      for _, config in ipairs(dap.configurations.go or {}) do
        if not seen[config.name] then
          table.insert(unique_configs, config)
          seen[config.name] = true
        end
      end

      table.insert(unique_configs, 1, {
        name = "Attach To Headless (127.0.0.1:2346)",
        type = "go",
        request = "attach",
        mode = "remote",
        host = "127.0.0.1",
        port = 2346,
      })
      table.insert(unique_configs, 1, {
        name = "Attach To Headless (127.0.0.1:2345)",
        type = "go",
        request = "attach",
        mode = "remote",
        host = "127.0.0.1",
        port = 2345,
      })

      dap.configurations.go = unique_configs

      dap.listeners.after.event_initialized["dapview_config"] = function()
        close_neotree()
        dapview.open()
      end
      dap.listeners.before.event_terminated["dapview_config"] = function()
        close_neotree()
        dapview.close(true)
      end
      dap.listeners.before.event_exited["dapview_config"] = function()
        close_neotree()
        dapview.close(true)
      end

      vim.api.nvim_create_autocmd("FileType", {
        pattern = { "dap-view", "dap-view-term", "dap-repl" },
        callback = function(args)
          local keymaps = {
            { "<Leader>dc", dap.continue, "Start/Continue Debugging" },
            { "<Leader>dn", dap.step_over, "Step Over" },
            { "<Leader>di", dap.step_into, "Step Into" },
            { "<Leader>do", dap.step_out, "Step Out" },
            { "<Leader>db", dap.toggle_breakpoint, "Toggle Breakpoint" },
            { "<Leader>df", dap.focus_frame, "Focus" },
          }
          for _, km in ipairs(keymaps) do
            vim.keymap.set("n", km[1], km[2], { buffer = args.buf, desc = km[3] })
          end
        end,
      })
    end,

    keys = function()
      local dap = require("dap")
      local dap_go = require("dap-go")
      return {
        {
          "<Leader>du",
          function()
            close_neotree()
            require("dap-view").toggle()
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
          "<Leader>dB",
          function()
            local condition = vim.fn.input("Breakpoint condition: ")
            if condition ~= "" then
              require("dap").set_breakpoint(condition)
            end
          end,
          desc = "Set Conditional Breakpoint",
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
