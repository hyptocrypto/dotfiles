return {
  "mfussenegger/nvim-lint",
  opts = function(_, opts)
    opts = opts or {}
    opts.linters_by_ft = vim.tbl_deep_extend("force", opts.linters_by_ft or {}, {
      -- SQL: sqlfluff with noisy rules disabled via nvim config
      sql = { "sqlfluff" },
      pgsql = { "sqlfluff" },
      -- Disable Go linting via golangci-lint (use gopls diagnostics instead)
      go = {},
    })

    opts.linters = vim.tbl_deep_extend("force", opts.linters or {}, {
      -- If golangci-lint is used elsewhere, treat exit code 3 as non-fatal
      golangcilint = {
        exit_codes = { 0, 1, 3 },
      },
      -- sqlfluff: use config from nvim config directory
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
