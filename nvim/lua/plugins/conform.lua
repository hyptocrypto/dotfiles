return {
  "stevearc/conform.nvim",
  opts = {
    -- Ensure we use ESLint for JS/TS/Vue and sqlfluff for SQL
    formatters_by_ft = {
      sql = { "sqlfluff_format" },
      pgsql = { "sqlfluff_format" },
      go = { "gofmt", "goimports" },
      html = { "djlint" },
      vue = { "eslint_d_fix" },
      javascript = { "eslint_d_fix" },
      javascriptreact = { "eslint_d_fix" },
      typescript = { "eslint_d_fix" },
      typescriptreact = { "eslint_d_fix" },
    },
    formatters = {
      eslint_d_fix = {
        inherit = false,
        command = "eslint_d",
        -- Run on a temp file so ESLint v9 can --fix the file
        args = { "--fix", "--quiet", "$FILENAME" },
        stdin = false,
        tempfile_dir = ".",
        exit_codes = { 0, 1 }, -- 1 can mean warnings
        cwd = function()
          return vim.fn.getcwd()
        end,
      },
      sqlfluff_format = {
        inherit = false, -- do not merge with builtin 'sqlfluff'
        command = "sqlfluff",
        args = { "format", "--dialect=postgres", "-" },
        stdin = true,
        -- Treat exit code 1 (violations) as non-fatal so Conform doesn't error
        exit_codes = { 0, 1 },
        cwd = function()
          return vim.fn.getcwd()
        end,
      },
    },
    notify_on_error = true,
  },
}
