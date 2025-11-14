return {
  "neovim/nvim-lspconfig",
  event = "VeryLazy",
  opts = {
    -- Performance optimizations

    -- Hard-disable inlay hints for JS/TS/Vue buffers on attach (Neovim 0.10+)
    -- Also disable redundant formatting to prevent multiple formatters running on save
    on_attach = function(client, bufnr)
      -- Hide inline diagnostics in markdown buffers (keep them for Trouble)
      if vim.bo[bufnr].filetype == "markdown" then
        pcall(vim.diagnostic.config, {
          virtual_text = false,
          virtual_lines = false,
          signs = false,
          underline = false,
          update_in_insert = false,
        }, bufnr)
      end
      if client.name == "vtsls" or client.name == "volar" then
        pcall(function()
          if vim.lsp.inlay_hint and vim.lsp.inlay_hint.enable then
            vim.lsp.inlay_hint.enable(false, { bufnr = bufnr })
          end
        end)
      end
      
      -- Disable formatting for ESLint (use conform.nvim instead)
      if client.name == "eslint" then
        client.server_capabilities.documentFormattingProvider = false
        client.server_capabilities.documentRangeFormattingProvider = false
      end
      
      -- Disable formatting for vtsls/volar (use conform.nvim/eslint_d instead)
      if client.name == "vtsls" or client.name == "volar" then
        client.server_capabilities.documentFormattingProvider = false
        client.server_capabilities.documentRangeFormattingProvider = false
      end
    end,

    -- Faster LSP startup
    single_file_support = true,

    servers = {
      -- Default capabilities for all servers
      ["*"] = {
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
      },
      -- Go linters (langserver)
      golangci_lint_ls = {
        cmd = { "golangci-lint-langserver" },
        filetypes = { "go", "gomod" },
        root_dir = require("lspconfig.util").root_pattern("go.work", "go.mod", ".git"),
      },

      -- Vue (Volar)
      volar = {
        -- Let Volar handle only Vue SFCs; TS/JS handled by vtsls
        filetypes = { "vue" },
        init_options = {
          -- Use Volar hybrid mode to integrate with the TS server
          vue = { hybridMode = true },
        },
        settings = {
          volar = {
            validation = { template = true, script = true, style = true, hover = true },
          },
          -- Keep TS inlay hints disabled if routed via Volar
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
            updateImportsOnFileMove = { enabled = "prompt" },
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
            updateImportsOnFileMove = { enabled = "prompt" },
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

      -- Grammar and spell checking for prose
      ltex = {
        filetypes = { "markdown", "text", "gitcommit", "latex" },
        settings = {
          ltex = {
            language = "en-US",
            -- Run checks while editing with debounce to prevent slowdowns
            checkFrequency = "edit",
          },
        },
      },

      -- YAML
      yamlls = {},

      -- Python (configured in python.lua)

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
