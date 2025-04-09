return {
  "neovim/nvim-lspconfig",
  opts = {
    servers = {

      golangci_lint_ls = {
        cmd = { "golangci-lint-langserver" },
        filetypes = { "go", "gomod" },
        root_dir = require("lspconfig.util").root_pattern("go.work", "go.mod", ".git"),
        init_options = {
          command = { "golangci-lint", "run", "--out-format", "json" },
        },
      },
      -- Volar for Vue files
      volar = {
        filetypes = { "vue" },
        init_options = {
          vue = { hybridMode = false },
        },
        settings = {
          volar = {
            validation = { template = true, script = true, style = true, hover = true },
          },
        },
      },

      -- TypeScript & JavaScript LSP
      tsserver = {
        filetypes = { "javascript", "javascriptreact", "typescript", "typescriptreact" },
      },

      -- JSON Language Server
      jsonls = {},

      -- CSS, SCSS, and Tailwind LSP
      cssls = {
        filetypes = { "css", "scss", "less" },
      },
      tailwindcss = {
        filetypes = { "vue", "javascript", "typescript", "html", "css", "scss" },
      },

      -- Markdown and Docs LSP
      marksman = {},

      -- YAML LSP
      yamlls = {},

      -- Python LSP
      pyright = {},

      -- Go LSP with Advanced Config
      gopls = {
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
              nilness = true,
              unusedparams = true,
              unusedwrite = true,
              fieldalignment = true,
              shadow = true,
              unusedvariable = true,
              ST1000 = true, -- style checks
              ST1005 = true,
              unusedresult = true,
              unreachable = true,
              loopclosure = true,
              lostcancel = true,
              printf = true,
              ifaceassert = true,
              stringintconv = true,
              atomicalign = true,
              undeclaredname = true,
              fillreturns = true,
              nonewvars = true,
              stacktrace = true,
            },
            usePlaceholders = true,
            completeUnimported = true,
            staticcheck = true,
            directoryFilters = { "-.git", "-.vscode", "-.idea", "-.vscode-test", "-node_modules" },
            semanticTokens = true,
          },
        },
      },

      -- Docker LSP
      dockerls = {},
      docker_compose_language_service = {},

      -- ESLint for linting errors
      eslint = {
        settings = {
          validate = "on",
          packageManager = "npm",
          autoFixOnSave = true,
          format = true,
          workingDirectory = { mode = "auto" },
        },
      },
    },
  },
}
