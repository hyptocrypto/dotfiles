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

lspconfig.gopls.setup({
  on_attach = function(client, bufnr)
    if client.server_capabilities.codeLensProvider then
      vim.api.nvim_create_autocmd({ "BufEnter", "CursorHold", "InsertLeave" }, {
        buffer = bufnr,
        callback = function()
          vim.lsp.codelens.refresh()
        end,
      })
    end
  end,
  settings = {
    gopls = {
      gofumpt = true,
      codelenses = {
        gc_details = true,
        generate = true,
        regenerate_cgo = true,
        run_govulncheck = true,
        test = true,
        tidy = true,
        upgrade_dependency = true,
        vendor = true,
      },
      hints = {
        assignVariableTypes = false,
        compositeLiteralFields = false,
        compositeLiteralTypes = false,
        constantValues = false,
        functionTypeParameters = false,
        parameterNames = false,
        rangeVariableTypes = false,
      },
      analyses = {
        fieldalignment = true,
        nilness = true,
        unusedparams = true,
        unusedwrite = true,
        useany = true,
      },
      usePlaceholders = true,
      completeUnimported = true,
      staticcheck = true,
      directoryFilters = { "-.git", "-.vscode", "-.idea", "-.vscode-test", "-node_modules" },
      semanticTokens = true,
    },
  },
  -- other options
})

--- Snacks pickers
vim.keymap.set("n", "<leader>,", function()
  Snacks.picker.buffers({})
end, { desc = "[P]Snacks picker buffers" })

vim.keymap.set("n", "<leader>/", function()
  Snacks.picker.grep({})
end, { desc = "[P]Snacks picker grep" })

vim.keymap.set("n", "<leader><space>", function()
  Snacks.picker.files({})
end, { desc = "[P]Snacks picker grep" })
