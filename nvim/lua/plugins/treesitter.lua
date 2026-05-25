return {
  "nvim-treesitter/nvim-treesitter",
  branch = "main",
  lazy = false,
  build = ":TSUpdate",
  config = function()
    require("nvim-treesitter").setup()

    local parsers = {
      "bash", "c", "cpp", "css", "dockerfile", "gitignore",
      "go", "gomod", "gosum", "html", "htmldjango", "javascript",
      "json", "jsonc", "lua", "markdown", "markdown_inline", "python",
      "regex", "rust", "sql", "svelte", "toml", "tsx", "typescript",
      "vim", "vue", "yaml",
    }

    local installed = require("nvim-treesitter.config").get_installed()
    local missing = vim.iter(parsers):filter(function(p)
      return not vim.tbl_contains(installed, p)
    end):totable()

    if #missing > 0 then
      require("nvim-treesitter").install(missing)
    end

    local dap_filetypes = { "dap-view", "dap-view-term", "dap-view-hover", "dap-view-help", "dap-repl" }

    vim.api.nvim_create_autocmd("FileType", {
      callback = function()
        if vim.tbl_contains(dap_filetypes, vim.bo.filetype) then
          return
        end
        pcall(vim.treesitter.start)
        vim.bo.indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
      end,
    })

    vim.api.nvim_create_autocmd("FileType", {
      pattern = "dap-repl",
      callback = function(args)
        local src_ft = vim.b[args.buf]["dap-srcft"]
        if src_ft then
          local lang = vim.treesitter.language.get_lang(src_ft)
          if lang then
            pcall(vim.treesitter.start, args.buf, lang)
          end
        end
      end,
    })
  end,
}
