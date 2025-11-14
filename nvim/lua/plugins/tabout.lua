return {
  {
    "abecodes/tabout.nvim",
    lazy = false,
    config = function()
      require("tabout").setup({

        -- Disable explicit tab mappings so Blink can own <Tab> / <S-Tab>
        tabkey = "",
        backwards_tabkey = "",

        act_as_tab = true,
        act_as_shift_tab = false,

        default_tab = "<C-t>",
        default_shift_tab = "<C-d>",

        enable_backwards = true,

        completion = false, -- don't tabout when completion menu is open

        tabouts = {
          { open = "'", close = "'" },
          { open = '"', close = '"' },
          { open = "`", close = "`" },
          { open = "(", close = ")" },
          { open = "[", close = "]" },
          { open = "{", close = "}" },
        },

        ignore_beginning = true,
        exclude = {},
      })
    end,

    dependencies = {
      "nvim-treesitter/nvim-treesitter",
      "L3MON4D3/LuaSnip",
    },
    event = "InsertCharPre",
    priority = 1000,
  },

  -- Disable LuaSnip tab mappings (good)
  {
    "L3MON4D3/LuaSnip",
    keys = function()
      return {}
    end,
  },
} -- Lua
