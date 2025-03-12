return {
  {
    "LazyVim/LazyVim",
    keys = {
      -- Move between windows using Ctrl/cmd + hjkl
      { "<C-k>", "<C-w>w", desc = "Move to next window", mode = "n" },
      { "<C-j>", "<C-w>W", desc = "Move to previous window", mode = "n" },

      { "<D-k>", "<C-w>w", desc = "Move to next window", mode = "n" },
      { "<D-j>", "<C-w>W", desc = "Move to previous window", mode = "n" },

      -- Resize windows using Ctrl + Alt + hjkl
      { "<C-M-h>", "<C-w><", desc = "Resize window left", mode = "n" },
      { "<C-M-l>", "<C-w>>", desc = "Resize window right", mode = "n" },
      { "<C-M-j>", "<C-w>-", desc = "Resize window down", mode = "n" },
      { "<C-M-k>", "<C-w>+", desc = "Resize window up", mode = "n" },
    },
  },
}
