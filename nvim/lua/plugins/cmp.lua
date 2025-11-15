local patch = require("blink_patch")

return {
  {
    "saghen/blink.cmp",
    opts = function(_, opts)
      opts = patch(opts)

      -- Make Blink own <Tab>/<S-Tab> navigation when menu is visible
      opts.keymap = vim.tbl_deep_extend("force", opts.keymap or {}, {
        ["<Tab>"] = { "select_next", "fallback" },
        ["<S-Tab>"] = { "select_prev", "fallback" },
      })

      return opts
    end,
  },
}
