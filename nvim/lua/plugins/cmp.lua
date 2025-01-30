return {
  {
    "saghen/blink.cmp",
    version = "v0.*",
    opts = function(_, opts)
      opts.keymap = vim.tbl_deep_extend("force", opts.keymap or {}, {
        preset = "enter",
        ["<Tab>"] = { "select_next", "snippet_forward", "fallback" },
        ["<S-Tab>"] = { "select_prev", "snippet_backward", "fallback" },
      })

      opts.completion = vim.tbl_deep_extend("force", opts.completion or {}, {
        list = {
          selection = { auto_insert = true },
        },
      })

      return opts
    end,
  },
}
