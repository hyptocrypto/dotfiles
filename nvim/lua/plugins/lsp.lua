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
    -- Faster LSP startup
    single_file_support = true,
    servers = {
      golangci_lint_ls = {
        cmd = {
          "golangci-lint-langserver",
        },
        filetypes = { "go", "gomod" },
        root_dir = require("lspconfig.util").root_pattern("go.work", "go.mod", ".git"),
      },
      -- Volar for Vue files
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
        },
      },
      ts_ls = {
        init_options = {
          plugins = {
            {
              name = "@vue/typescript-plugin",
              location = vim.fn.stdpath("data")
                .. "/mason/packages/vue-language-server/node_modules/@vue/language-server",
              languages = { "vue" },
            },
          },
        },
      },
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

      -- Go LSP with Optimized Config
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
            directoryFilters = { "-.git", "-.vscode", "-.idea", "-.vscode-test", "-node_modules", "-vendor-patched", "-testdata" },
            semanticTokens = true,
            staticcheck = true,
            experimentalPostfixCompletions = true,
          },
        },
      },

      -- Docker LSP
      dockerls = {},
      docker_compose_language_service = {},
    },
  },
}
