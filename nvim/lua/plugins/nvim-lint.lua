return {
  "mfussenegger/nvim-lint",
  opts = function(_, opts)
    opts = opts or {}
    -- Use sqlfluff for SQL diagnostics with Postgres dialect
    opts.linters_by_ft = vim.tbl_deep_extend("force", opts.linters_by_ft or {}, {
      sql = { "sqlfluff" },
      pgsql = { "sqlfluff" },
    })

    opts.linters = vim.tbl_deep_extend("force", opts.linters or {}, {
      sqlfluff = {
        args = { "lint", "--format=json", "--dialect=postgres" },
      },
    })

    return opts
  end,
}
