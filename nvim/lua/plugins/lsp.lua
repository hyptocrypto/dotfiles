-- See: https://github.com/neovim/nvim-lspconfig/blob/master/doc/configs.md#vue-support
local vue_language_server_path = vim.fn.expand("$MASON/packages")
  .. "/vue-language-server"
  .. "/node_modules/@vue/language-server"
local vue_plugin = {
  name = "@vue/typescript-plugin",
  location = vue_language_server_path,
  languages = { "vue" },
  configNamespace = "typescript",
}

-- Set rounded borders for LspInfo window
require("lspconfig.ui.windows").default_options.border = "rounded"

return {
  "neovim/nvim-lspconfig",
  event = "VeryLazy",
  opts = {
    -- Faster LSP startup
    single_file_support = true,

    servers = {
      -- Go linters (langserver)

      golangci_lint_ls = {
        cmd = { "golangci-lint-langserver" },
        filetypes = { "go", "gomod" },

        -- allow LazyVim to choose the correct project root:
        -- (do NOT set root_dir here)
        init_options = {
          command = {
            "/Users/julianbaumgartner/go/bin/golangci-lint",
            "run",
            "--out-format",
            "json",
          },
        },
      },

      -- Vue (Volar)
      vue_ls = {
        filetypes = { "vue" },
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
        filetypes = { "typescript", "javascript", "javascriptreact", "typescriptreact", "vue" },
        on_attach = function(client, bufnr)
          if vim.bo[bufnr].filetype == "vue" then
            -- Disable only diagnostics; keep all other features
            client.server_capabilities.diagnosticProvider = false
            client.handlers["textDocument/publishDiagnostics"] = function() end
          end
        end,
        settings = {
          vtsls = {
            definition = {
              enableDefinitionLinks = true,
              fallbackToModuleFile = true,
            },
            autoUseWorkspaceTsdk = true,
            enableMoveToFileCodeAction = true,
            experimental = {
              completion = { enableServerSideFuzzyMatch = true },
              -- not needed, but ensure no long hints if something flips them on
              maxInlayHintLength = 0,
            },
            tsserver = {
              globalPlugins = {
                vue_plugin,
              },
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
        filetypes = { "javascript", "typescript", "html", "css", "scss" },
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
