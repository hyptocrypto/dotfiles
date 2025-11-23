return {
  "mfussenegger/nvim-lint",
  opts = function(_, opts)
    opts = opts or {}
    -- Use sqlfluff for SQL diagnostics with Postgres dialect
    opts.linters_by_ft = vim.tbl_deep_extend("force", opts.linters_by_ft or {}, {
      sql = { "sqlfluff" },
      pgsql = { "sqlfluff" },
      -- Disable Go linting via golangci-lint (use gopls diagnostics instead)
      go = {},
    })

    opts.linters = vim.tbl_deep_extend("force", opts.linters or {}, {
      sqlfluff = {
        args = { "lint", "--format=json", "--dialect=postgres" },
      },
      -- If golangci-lint is used elsewhere, treat exit code 3 as non-fatal
      golangcilint = {
        exit_codes = { 0, 1, 3 },
      },
    })

    return opts
  end,
}
