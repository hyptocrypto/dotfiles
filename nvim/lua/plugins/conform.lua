return {
  "stevearc/conform.nvim",
  opts = {
    formatters_by_ft = {
      go = { "gofmt", "goimports" },
      html = { "djlint" },
      -- Vue/JS/TS use LspEslintFixAll via autocmd instead (see autocmds.lua)
      -- autoformat disabled via vim.b.autoformat = false in autocmds.lua
      vue = {},
      javascript = {},
      javascriptreact = {},
      typescript = {},
      typescriptreact = {},
      -- SQL: use sqlfluff for better multi-line formatting (config in ~/.sqlfluff)
      sql = { "sqlfluff" },
      pgsql = { "sqlfluff" },
    },
    formatters = {
      sqlfluff = {
        args = function()
          local config = vim.fn.stdpath("config") .. "/extra/.sqlfluff"
          return { "fix", "--force", "--config", config, "-" }
        end,
      },
    },
    notify_on_error = true,
  },
}
