return {
  "ThePrimeagen/harpoon",
  lazy = false,
  dependencies = {
    "nvim-lua/plenary.nvim",
  },
  config = true,
  keys = {
    {
      "<leader>ha",
      function()
        require("harpoon.mark").add_file()
        vim.notify("File marked with Harpoon", vim.log.levels.INFO)
      end,
      desc = "Mark file with harpoon",
    },
    {
      "<leader>hh",
      function()
        require("harpoon.ui").toggle_quick_menu()
      end,
      desc = "Show harpoon marks",
    },
    {
      "<leader>hc",
      function()
        require("harpoon.mark").clear_all()
        vim.notify("Cleared all Harpoon marks", vim.log.levels.WARN)
      end,
      desc = "Clear all harpoon marks",
    },
  },
}
