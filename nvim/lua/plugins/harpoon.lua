return {
  "ThePrimeagen/harpoon",
  lazy = false,
  dependencies = {
    "nvim-lua/plenary.nvim",
  },
  menu = {
    width = vim.api.nvim_win_get_width(0) - 10,
    keymaps = {
      ["<Tab>"] = function(menu)
        menu:select_next()
      end,
      ["<S-Tab>"] = function(menu)
        menu:select_prev()
      end,
    },
  },
  config = true,
  keys = {
    { "<leader>ha", "<cmd>lua require('harpoon.mark').add_file()<cr>", desc = "Mark file with harpoon" },
    { "<leader>hh", "<cmd>lua require('harpoon.ui').toggle_quick_menu()<cr>", desc = "Show harpoon marks" },
  },
}
