return {
  "neovim/nvim-lspconfig",
  opts = {
    servers = {
      -- Volar for Vue files
      volar = {
        filetypes = { "vue" },
        init_options = {
          vue = { hybridMode = false },
        },
        settings = {
          volar = {
            validation = { template = true, script = true, style = true },
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
        },
      },
    },
  },
}
