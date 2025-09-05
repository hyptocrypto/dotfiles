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
        -- Ensure grep & files always search from project root and include hidden & ignored files
        sources = {
          grep = {
            hidden = true,
            ignored = true,
            -- extra ripgrep args to include absolutely everything
            -- be explicit to avoid env-specific rg defaults
            args = { "--hidden", "--no-ignore", "--no-ignore-global", "--no-ignore-parent" },
            -- keep some heavy/system paths excluded to avoid noise
            exclude = {
              "**/node_modules/**",
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
              "**/.DS_Store",
              "**/Thumbs.db",
            },
            -- dynamically set cwd to project root for every grep invocation
            config = function(o)
              local ok, util = pcall(require, "lazyvim.util")
              if ok then
                o.cwd = util.root()
              else
                o.cwd = o.cwd or vim.fn.getcwd()
              end
              return o
            end,
          },
          files = {
            hidden = true,
            ignored = true,
            -- do not set args so this works with both fd and rg
            exclude = {
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
              "**/.DS_Store",
              "**/Thumbs.db",
            },
            -- dynamically set cwd to project root for every files invocation
            config = function(o)
              local ok, util = pcall(require, "lazyvim.util")
              if ok then
                o.cwd = util.root()
              else
                o.cwd = o.cwd or vim.fn.getcwd()
              end
              return o
            end,
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
