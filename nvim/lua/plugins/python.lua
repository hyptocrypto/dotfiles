return {
  {
    "neovim/nvim-lspconfig",
    opts = {
      servers = {
        pyright = {
          on_new_config = function(config, root_dir)
            -- Look for .venv in the project root
            local venv_python = root_dir .. "/.venv/bin/python"
            local venv_path = root_dir .. "/.venv"
            
            if vim.fn.filereadable(venv_python) == 1 then
              config.settings = config.settings or {}
              config.settings.python = config.settings.python or {}
              config.settings.python.pythonPath = venv_python
              config.settings.python.venvPath = root_dir
              config.settings.python.analysis = config.settings.python.analysis or {}
              config.settings.python.analysis.autoSearchPaths = true
              
              -- Add site-packages to extraPaths
              local site_packages = root_dir .. "/.venv/lib/python*/site-packages"
              config.settings.python.analysis.extraPaths = { site_packages }
            end
          end,
        },
      },
    },
  },
  {
    "stevearc/conform.nvim",
    opts = {
      formatters_by_ft = {
        python = { "ruff_format" },
      },
      formatters = {
        ruff_format = {
          inherit = false,
          command = "ruff",
          args = { "format", "--stdin-filename", "$FILENAME", "-" },
          stdin = true,
        },
      },
    },
  },
  {
    "mfussenegger/nvim-lint",
    opts = {
      linters_by_ft = {
        python = { "ruff" },
      },
      linters = {
        ruff = {
          cmd = "ruff",
          args = { "check", "--stdin-filename", "$FILENAME", "-" },
          stdin = true,
        },
      },
    },
  },
}