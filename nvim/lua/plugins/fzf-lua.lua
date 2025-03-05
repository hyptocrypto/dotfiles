return {
  "ibhagwan/fzf-lua",
  keys = {
    {
      "<leader>gd",
      function()
        require("fzf-lua").git_status()
      end,
      desc = "Git Status (fzf-lua)",
    },
    {
      "<leader><Space>",
      function()
        require("fzf-lua").files({ cwd = vim.fn.getcwd() })
      end,
      desc = "Find Files (Root Dir)",
    },

    {
      "<leader>/",
      function()
        require("fzf-lua").live_grep({ cwd = require("lazyvim.util").root() })
      end,
      desc = "Live Grep (Root Dir)",
    },

    {
      "<leader>Ds",
      function()
        -- Use fzf to pick a directory before running live_grep
        require("fzf-lua").live_grep_glob()
      end,
      desc = "Live Grep in Specific Directory",
    },
  },
  config = function()
    require("fzf-lua").setup({
      keymap = {
        builtin = {
          ["<Tab>"] = "down",
          ["<S-Tab>"] = "up",
        },
        fzf = {
          ["tab"] = "down",
          ["shift-tab"] = "up",
        },
      },
    })
  end,
}
