return {
  "nvim-treesitter/nvim-treesitter",
  run = ":TSUpdate",
  config = function()
    require("nvim-treesitter.configs").setup({
      ensure_installed = { "htmldjango", "html", "go", "javascript", "vue" },
      highlight = {
        enable = true,
        additional_vim_regex_highlighting = true,
      },
      indent = { enable = true },
    })
  end,
}
