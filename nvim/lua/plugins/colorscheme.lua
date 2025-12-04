return {
  "projekt0n/github-nvim-theme",
  name = "github-theme",
  lazy = false,
  priority = 1000,
  config = function()
    require("github-theme").setup({
      options = {
        styles = {
          comments = "italic",
        },
      },
    })

    vim.cmd("colorscheme github_dark")

    -- Make floating windows blend seamlessly with the background
    local normal_bg = vim.api.nvim_get_hl(0, { name = "Normal" }).bg
    local bg_hex = normal_bg and string.format("#%06x", normal_bg) or "#0d1117"

    -- Bolder border color for floating windows
    local bold_border = "#7d8590"

    -- Set floating window highlights to match editor background
    vim.api.nvim_set_hl(0, "NormalFloat", { bg = bg_hex })
    vim.api.nvim_set_hl(0, "FloatBorder", { bg = bg_hex, fg = bold_border })
    vim.api.nvim_set_hl(0, "FloatTitle", { bg = bg_hex, fg = "#c9d1d9", bold = true })

    -- LSP hover and signature help borders
    vim.api.nvim_set_hl(0, "LspInfoBorder", { bg = bg_hex, fg = bold_border })
    vim.api.nvim_set_hl(0, "LspFloatWinBorder", { bg = bg_hex, fg = bold_border })

    -- Completion menu
    vim.api.nvim_set_hl(0, "Pmenu", { bg = bg_hex })
    vim.api.nvim_set_hl(0, "PmenuSel", { bg = "#21262d" })
    vim.api.nvim_set_hl(0, "PmenuSbar", { bg = bg_hex })
    vim.api.nvim_set_hl(0, "PmenuThumb", { bg = "#484f58" })

    -- Which-key
    vim.api.nvim_set_hl(0, "WhichKeyFloat", { bg = bg_hex })
    vim.api.nvim_set_hl(0, "WhichKeyBorder", { bg = bg_hex, fg = "#484f58" })

    -- Telescope / Snacks picker
    vim.api.nvim_set_hl(0, "TelescopeNormal", { bg = bg_hex })
    vim.api.nvim_set_hl(0, "TelescopeBorder", { bg = bg_hex, fg = "#484f58" })

    -- Lazy.nvim
    vim.api.nvim_set_hl(0, "LazyNormal", { bg = bg_hex })

    -- Mason
    vim.api.nvim_set_hl(0, "MasonNormal", { bg = bg_hex })

    -- Noice
    vim.api.nvim_set_hl(0, "NoicePopup", { bg = bg_hex })
    vim.api.nvim_set_hl(0, "NoicePopupBorder", { bg = bg_hex, fg = "#484f58" })
    vim.api.nvim_set_hl(0, "NoiceCmdlinePopup", { bg = bg_hex })
    vim.api.nvim_set_hl(0, "NoiceCmdlinePopupBorder", { bg = bg_hex, fg = "#484f58" })

    -- Snacks picker and windows (bolder borders)
    local snacks_border = "#7d8590" -- Brighter, more visible border color
    vim.api.nvim_set_hl(0, "SnacksNormal", { bg = bg_hex })
    vim.api.nvim_set_hl(0, "SnacksBorder", { bg = bg_hex, fg = snacks_border })
    vim.api.nvim_set_hl(0, "SnacksWinBar", { bg = bg_hex })
    vim.api.nvim_set_hl(0, "SnacksBackdrop", { bg = "NONE" })
    vim.api.nvim_set_hl(0, "SnacksPickerBoxBorder", { bg = bg_hex, fg = snacks_border })
    vim.api.nvim_set_hl(0, "SnacksPickerBox", { bg = bg_hex })
    vim.api.nvim_set_hl(0, "SnacksPicker", { bg = bg_hex })
    vim.api.nvim_set_hl(0, "SnacksPickerBorder", { bg = bg_hex, fg = snacks_border })
    vim.api.nvim_set_hl(0, "SnacksPickerTitle", { bg = bg_hex, fg = "#c9d1d9", bold = true })
    vim.api.nvim_set_hl(0, "SnacksPickerInput", { bg = bg_hex })
    vim.api.nvim_set_hl(0, "SnacksPickerInputBorder", { bg = bg_hex, fg = snacks_border })
    vim.api.nvim_set_hl(0, "SnacksPickerList", { bg = bg_hex })
    vim.api.nvim_set_hl(0, "SnacksPickerListBorder", { bg = bg_hex, fg = snacks_border })
    vim.api.nvim_set_hl(0, "SnacksPickerPreview", { bg = bg_hex })
    vim.api.nvim_set_hl(0, "SnacksPickerPreviewBorder", { bg = bg_hex, fg = snacks_border })
    vim.api.nvim_set_hl(0, "SnacksPickerPrompt", { bg = bg_hex })
    vim.api.nvim_set_hl(0, "SnacksPickerPromptBorder", { bg = bg_hex, fg = snacks_border })
    vim.api.nvim_set_hl(0, "SnacksNotifierInfo", { bg = bg_hex })
    vim.api.nvim_set_hl(0, "SnacksNotifierWarn", { bg = bg_hex })
    vim.api.nvim_set_hl(0, "SnacksNotifierError", { bg = bg_hex })
    vim.api.nvim_set_hl(0, "SnacksNotifierDebug", { bg = bg_hex })
    vim.api.nvim_set_hl(0, "SnacksNotifierTrace", { bg = bg_hex })
    vim.api.nvim_set_hl(0, "SnacksInputNormal", { bg = bg_hex })
    vim.api.nvim_set_hl(0, "SnacksInputBorder", { bg = bg_hex, fg = snacks_border })
    vim.api.nvim_set_hl(0, "SnacksInputTitle", { bg = bg_hex, fg = "#c9d1d9", bold = true })
  end,
}
