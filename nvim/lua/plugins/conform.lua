return {
  "stevearc/conform.nvim",
  opts = {
    formatters_by_ft = {
      sql = { "sqlfluff" },
      pgsql = { "sqlfluff" },
      go = { "gofmt", "goimports" },
      html = { "djlint" },
      vue = { "eslint" },
      javascript = { "eslint" },
      javascriptreact = { "eslint" },
      typescript = { "eslint" },
      typescriptreact = { "eslint" },
    },
    formatters = {
      eslint = {
        command = "yarn",
        args = { "eslint", "--fix", "--stdin", "--stdin-filename", "$FILENAME" },
        stdin = true,
        cwd = function()
          return vim.fn.getcwd()
        end,
      },
      sqlfluff = {
        command = "sqlfluff",
        args = { "format", "--dialect=postgres", "-" },
        stdin = true,
        cwd = function()
          return vim.fn.getcwd()
        end,
      },
    },
  },
}
