return {
  "neovim/nvim-lspconfig",
  event = "VeryLazy",
  opts = {
    -- Performance optimizations
    capabilities = {
      textDocument = {
        completion = {
          completionItem = {
            snippetSupport = true,
            resolveSupport = {
              properties = { "documentation", "detail", "additionalTextEdits" },
            },
          },
        },
      },
    },

    -- Hard-disable inlay hints for JS/TS/Vue buffers on attach (Neovim 0.10+)
    on_attach = function(client, bufnr)
      if client.name == "vtsls" or client.name == "volar" then
        pcall(function()
          if vim.lsp.inlay_hint and vim.lsp.inlay_hint.enable then
            vim.lsp.inlay_hint.enable(false, { bufnr = bufnr })
          end
        end)
      end
    end,

    -- Faster LSP startup
    single_file_support = true,

    servers = {
      -- Go linters (langserver)
      golangci_lint_ls = {
        cmd = { "golangci-lint-langserver" },
        filetypes = { "go", "gomod" },
        root_dir = require("lspconfig.util").root_pattern("go.work", "go.mod", ".git"),
      },

      -- Vue (Volar)
      volar = {
        filetypes = { "vue", "javascript", "typescript", "json" },
        init_options = {
          typescript = {
            tsdk = vim.fn.stdpath("data") .. "/mason/packages/typescript-language-server/node_modules/typescript/lib",
          },
          vue = { hybridMode = false },
        },
        settings = {
          volar = {
            validation = { template = true, script = true, style = true, hover = true },
          },
          -- Also disable TS inlay hints routed via Volar
          typescript = {
            inlayHints = {
              enumMemberValues = { enabled = false },
              functionLikeReturnTypes = { enabled = false },
              parameterNames = { enabled = "none" },
              parameterTypes = { enabled = false },
              propertyDeclarationTypes = { enabled = false },
              variableTypes = { enabled = false },
            },
          },
        },
      },

      -- TypeScript/JavaScript (VTSLS) — replaces ts_ls/tsserver
      vtsls = {
        settings = {
          vtsls = {
            autoUseWorkspaceTsdk = true,
            enableMoveToFileCodeAction = true,
            experimental = {
              completion = { enableServerSideFuzzyMatch = true },
              -- not needed, but ensure no long hints if something flips them on
              maxInlayHintLength = 0,
            },
          },
          -- Disable ALL inlay hints for both TS & JS
          typescript = {
            inlayHints = {
              enumMemberValues = { enabled = false },
              functionLikeReturnTypes = { enabled = false },
              parameterNames = { enabled = "none" },
              parameterTypes = { enabled = false },
              propertyDeclarationTypes = { enabled = false },
              variableTypes = { enabled = false },
            },
            suggest = { completeFunctionCalls = true },
            updateImportsOnFileMove = { enabled = "always" },
          },
          javascript = {
            inlayHints = {
              enumMemberValues = { enabled = false },
              functionLikeReturnTypes = { enabled = false },
              parameterNames = { enabled = "none" },
              parameterTypes = { enabled = false },
              propertyDeclarationTypes = { enabled = false },
              variableTypes = { enabled = false },
            },
            suggest = { completeFunctionCalls = true },
            updateImportsOnFileMove = { enabled = "always" },
          },
        },
      },

      -- ESLint
      eslint = {
        settings = {
          validate = "on",
          packageManager = "yarn",
          format = true,
          workingDirectory = { mode = "auto" },
        },
      },

      -- JSON Language Server
      jsonls = {},

      -- CSS / SCSS / Less
      cssls = {
        filetypes = { "css", "scss", "less" },
      },
      tailwindcss = {
        filetypes = { "vue", "javascript", "typescript", "html", "css", "scss" },
      },

      -- Markdown / docs
      marksman = {},

      -- YAML
      yamlls = {},

      -- Python
      pyright = {},

      -- Go LSP with optimized config
      gopls = {
        settings = {
          gopls = {
            gofumpt = true,
            codelenses = {
              gc_details = false,
              generate = true,
              regenerate_cgo = true,
              run_govulncheck = false,
              test = true,
              tidy = true,
              upgrade_dependency = false,
              vendor = false,
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
              fieldalignment = false,
              shadow = false,
              unusedvariable = true,
              unusedresult = true,
              unreachable = true,
              loopclosure = true,
              lostcancel = true,
              printf = true,
              ifaceassert = true,
              stringintconv = true,
              atomicalign = false,
              undeclaredname = true,
              fillreturns = true,
              nonewvars = true,
              stacktrace = false,
            },
            usePlaceholders = true,
            completeUnimported = true,
            directoryFilters = {
              "-.git",
              "-.vscode",
              "-.idea",
              "-.vscode-test",
              "-node_modules",
              "-vendor-patched",
              "-testdata",
            },
            semanticTokens = true,
            staticcheck = true,
            experimentalPostfixCompletions = true,
          },
        },
      },

      -- Docker
      dockerls = {},
      docker_compose_language_service = {},
    },
  },
}
