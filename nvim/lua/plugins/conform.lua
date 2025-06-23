return {
  "stevearc/conform.nvim",
  opts = {
    opts = {
      default_format_opts = {
        lsp_format = "fallback",
        timeout_ms = 10000,
      },
    },
    formatters_by_ft = {
      sql = { "sqlfluff" },
      pgsql = { "sqlfluff" },
      go = { "goimports", "gofmt", "gopls" },
      html = { "djlint" },
      vue = { "eslint" },
      javascript = { "eslint" },
      javascriptreact = { "eslint" },
      typescript = { "eslint" },
      typescriptreact = { "eslint" },
    },

    formatters = {
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
