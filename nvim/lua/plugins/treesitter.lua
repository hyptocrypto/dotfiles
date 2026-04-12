return {
  "nvim-treesitter/nvim-treesitter",
  branch = "main",
  lazy = false,
  build = ":TSUpdate",
  config = function()
    require("nvim-treesitter").setup()

    local parsers = {
      "bash", "c", "cpp", "css", "dockerfile", "gitignore",
      "go", "gomod", "gosum", "html", "htmldjango", "javascript",
      "json", "jsonc", "lua", "markdown", "markdown_inline", "python",
      "regex", "rust", "sql", "svelte", "toml", "tsx", "typescript",
      "vim", "vue", "yaml",
    }

    local installed = require("nvim-treesitter.config").get_installed()
    local missing = vim.iter(parsers):filter(function(p)
      return not vim.tbl_contains(installed, p)
    end):totable()

    if #missing > 0 then
      require("nvim-treesitter").install(missing)
    end

    vim.api.nvim_create_autocmd("FileType", {
      callback = function()
        pcall(vim.treesitter.start)
        vim.bo.indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
      end,
    })
  end,
}
