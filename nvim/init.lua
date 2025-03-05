-- bootstrap lazy.nvim, LazyVim and your plugins
require("config.lazy")
-- Lazyvim LSP Configuration
local lspconfig = require("lspconfig")

lspconfig.eslint.setup({
  settings = {
    workingDirectory = { mode = "auto" },
  },
  on_attach = function(client, bufnr)
    -- Add your custom on_attach functions here
  end,
})
require("dap-go").setup()

lspconfig.ruff.setup({})
vim.api.nvim_create_autocmd("BufWritePost", {
  pattern = "*.py",
  callback = function()
    vim.lsp.buf.code_action({
      context = {
        only = {
          "source.fixAll.ruff",
        },
      },
      apply = true,
    })
    vim.lsp.buf.format({ async = false })
  end,
})

vim.o.completeopt = "menu,menuone,noselect"

-- Dont show leading whitespace dashes
vim.opt.list = false

-- Use system clipboard
vim.o.clipboard = "unnamedplus"

-- Set line numbers
vim.opt.number = true
vim.opt.relativenumber = true

-- Turn off backup
vim.opt.backup = false
vim.opt.writebackup = false
vim.opt.swapfile = false

-- Use spaces instead of tabs
vim.opt.expandtab = true
vim.opt.smarttab = true
vim.opt.shiftwidth = 4
vim.opt.tabstop = 4

vim.api.nvim_create_autocmd({ "UIEnter", "ColorScheme" }, {
  callback = function()
    local normal = vim.api.nvim_get_hl(0, { name = "Normal" })
    if not normal.bg then
      return
    end
    io.write(string.format("\027]11;#%06x\027\\", normal.bg))
  end,
})

vim.api.nvim_create_autocmd("UILeave", {
  callback = function()
    io.write("\027]111\027\\")
  end,
})
