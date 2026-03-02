return {
  "mfussenegger/nvim-lint",
  opts = function(_, opts)
    opts = opts or {}
    opts.linters_by_ft = vim.tbl_deep_extend("force", opts.linters_by_ft or {}, {
      sql = { "sqlfluff" },
      pgsql = { "sqlfluff" },
      go = {},
    })

    opts.linters = vim.tbl_deep_extend("force", opts.linters or {}, {
      sqlfluff = {
        args = {
          "lint",
          "--format=json",
          "--config",
          vim.fn.stdpath("config") .. "/extra/.sqlfluff",
          "-",
        },
      },
    })

    return opts
  end,
}
