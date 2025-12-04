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

      -- Soft rounded completion menu
      opts.completion = vim.tbl_deep_extend("force", opts.completion or {}, {
        menu = {
          border = "rounded",
          draw = {
            padding = 1,
            gap = 1,
            columns = {
              { "kind_icon" },
              { "label", "label_description", gap = 1 },
            },
          },
        },
        documentation = {
          auto_show = true,
          auto_show_delay_ms = 200,
          window = {
            border = "rounded",
          },
        },
        ghost_text = {
          enabled = true,
        },
      })

      -- Rounded signature help window
      opts.signature = vim.tbl_deep_extend("force", opts.signature or {}, {
        window = {
          border = "rounded",
        },
      })

      return opts
    end,
  },
}
