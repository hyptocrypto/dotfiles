return {
  "iamcco/markdown-preview.nvim",
  cmd = { "MarkdownPreview", "MarkdownPreviewStop", "MarkdownPreviewToggle" },
  ft = { "markdown" },
  build = "cd app && bash install.sh",
  init = function()
    vim.g.mkdp_auto_close = 0
  end,
}
