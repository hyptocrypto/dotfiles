-- Autocmds are automatically loaded on the VeryLazy event
-- Default autocmds that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/autocmds.lua
-- Define the function to run the formatting tools

-- Format templ files on save
vim.api.nvim_create_autocmd("BufWritePre", {
  pattern = "*.templ",
  callback = function()
    vim.lsp.buf.format({ async = true })
  end,
  desc = "Format templ files on save",
})

vim.api.nvim_create_user_command("Script", function()
  local row, col = unpack(vim.api.nvim_win_get_cursor(0))
  local line = vim.api.nvim_get_current_line()
  local new_line = line:sub(1, col) .. '<script src="">console.log()</script>' .. line:sub(col + 1)
  vim.api.nvim_set_current_line(new_line)
  vim.api.nvim_win_set_cursor(0, { row, col + 27 })
  vim.cmd("startinsert")
end, {})

vim.api.nvim_create_user_command("Jsfunc", function()
  -- Get the current cursor position
  local row, col = unpack(vim.api.nvim_win_get_cursor(0))

  -- Define the JavaScript arrow function snippet, with each line as a separate entry
  local arrow_function = {
    "() => {",
    "    ", -- Empty space for indentation
    "}",
  }

  -- Insert the snippet at the current cursor position
  vim.api.nvim_buf_set_text(0, row - 1, col, row - 1, col, arrow_function)

  -- Move the cursor inside the function body
  vim.api.nvim_win_set_cursor(0, { row + 1, col + 4 })
end, {})

vim.api.nvim_create_user_command("Golines", function()
  vim.cmd("silent! %!golines --max-len=130 --base-formatter=gofumpt")
end, {})

-- Auto-fix Python files with ruff and format on save
vim.api.nvim_create_autocmd("BufWritePre", {
  pattern = "*.py",
  callback = function()
    -- Only run if LSP is available
    if vim.lsp.buf_is_attached(0) then
      -- Run code actions asynchronously
      vim.lsp.buf.code_action({
        context = {
          only = {
            "source.fixAll.ruff",
          },
        },
        apply = true,
      })
    end
  end,
  desc = "Auto-fix Python files with ruff on save",
})

-- Disable LazyVim autoformat for Vue/JS/TS files (we use LspEslintFixAll instead)
vim.api.nvim_create_autocmd("FileType", {
  pattern = { "vue", "javascript", "javascriptreact", "typescript", "typescriptreact" },
  callback = function()
    vim.b.autoformat = false
  end,
  desc = "Disable LazyVim autoformat for Vue/JS/TS",
})

-- Auto-fix Vue/JS/TS files with ESLint LSP on save
vim.api.nvim_create_autocmd("BufWritePre", {
  pattern = { "*.vue", "*.js", "*.jsx", "*.ts", "*.tsx" },
  callback = function()
    -- Check if eslint LSP is attached to this buffer
    local clients = vim.lsp.get_clients({ bufnr = 0, name = "eslint" })
    if #clients > 0 then
      vim.cmd("LspEslintFixAll")
    end
  end,
  desc = "Auto-fix Vue/JS/TS files with ESLint LSP on save",
})
