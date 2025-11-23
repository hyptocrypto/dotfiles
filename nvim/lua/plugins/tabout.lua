return {
  "abecodes/tabout.nvim",
  event = "InsertEnter",
  opts = {
    tabkey = "<Tab>",
    backwards_tabkey = "<S-Tab>",
    act_as_tab = false,
    completion = false,
    tabouts = {
      { open = "'", close = "'" },
      { open = '"', close = '"' },
      { open = "`", close = "`" },
      { open = "(", close = ")" },
      { open = "[", close = "]" },
      { open = "{", close = "}" },
    },
  },
  dependencies = {
    "nvim-treesitter/nvim-treesitter",
    "L3MON4D3/LuaSnip",
  },
}
