return {
  {
    "folke/snacks.nvim",
    keys = {
      {
        "<leader><space>",
        function()
          Snacks.picker.smart()
        end,
        desc = "Smart Find Files",
      },
      {
        "<leader>,",
        function()
          Snacks.picker.buffers()
        end,
        desc = "Buffers",
      },
      {
        "<leader>/",
        function()
          Snacks.picker.grep()
        end,
        desc = "Grep",
      },
      {
        "<leader>:",
        function()
          Snacks.picker.command_history()
        end,
        desc = "Command History",
      },
      {
        "<leader>n",
        function()
          Snacks.notifier.show_history()
        end,
        desc = "Notification History",
      },
    },

    opts = {
      picker = {
        win = {
          input = {
            keys = {
              ["<S-Tab>"] = { "list_up", mode = { "i", "n" } },
              ["<Tab>"] = { "list_down", mode = { "i", "n" } },
            },
          },
        },
        debug = {
          scores = false, -- show scores in the list
        },
        matcher = {
          frecency = true,
        },
        formatters = {
          -- file = {
          --   filename_first = true, -- display filename before the file path
          --   truncate = 80,
          -- },
        },
      },
      image = {
        enabled = true,
        doc = {
          inline = true,
          float = true,
          max_width = 50,
          max_height = 50,
        },
      },
    },
  },
}
