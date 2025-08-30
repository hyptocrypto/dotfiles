return {
  {
    "folke/snacks.nvim",
    keys = {
      {
        "<leader><space>",
        function()
          -- Find files in current project only
          local root = require("lazyvim.util").root()
          Snacks.picker.files({ cwd = root })
        end,
        desc = "Find Files (Project)",
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
          -- Grep in current project only
          local root = require("lazyvim.util").root()
          Snacks.picker.grep({ cwd = root })
        end,
        desc = "Grep (Project)",
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
        -- Project-specific settings
        files = {
          follow_symlinks = false,
          show_hidden = true,
          ignore_patterns = {
            "**/node_modules/**",
            "**/.git/**",
            "**/vendor/**",
            "**/__pycache__/**",
            "**/.pytest_cache/**",
            "**/target/**",
            "**/dist/**",
            "**/build/**",
            "**/.next/**",
            "**/.nuxt/**",
            "**/coverage/**",
            "**/.nyc_output/**",
            "**/.cache/**",
            "**/tmp/**",
            "**/temp/**",
            -- Keep system dotfiles hidden but allow project dotfiles
            "**/.DS_Store",
            "**/Thumbs.db",
          },
        },
        grep = {
          show_hidden = true,
          ignore_patterns = {
            "**/node_modules/**",
            "**/.git/**",
            "**/vendor/**",
            "**/__pycache__/**",
            "**/.pytest_cache/**",
            "**/target/**",
            "**/dist/**",
            "**/build/**",
            "**/.next/**",
            "**/.nuxt/**",
            "**/coverage/**",
            "**/.nyc_output/**",
            "**/.cache/**",
            "**/tmp/**",
            "**/temp/**",
            -- Keep system dotfiles hidden but allow project dotfiles
            "**/.DS_Store",
            "**/Thumbs.db",
          },
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
