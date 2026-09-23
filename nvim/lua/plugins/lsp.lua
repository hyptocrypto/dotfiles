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

-- Translate sqmeow's saved connections into sqls' connection format, so the
-- SQL language server knows your schema without a second, separately
-- maintained credentials file. Only postgres/mysql/sqlite URLs are supported
-- (sqls' own limitation); other dialects (redis, mongo, ...) are skipped.
-- Re-run `:LspRestart` (or restart Neovim) after adding a connection in sqmeow.
local function sqls_connections()
  local path = vim.fs.joinpath(vim.fn.stdpath("data"), "sqmeow", "connections.json")
  local ok, lines = pcall(vim.fn.readfile, path)
  if not ok or #lines == 0 then
    return {}
  end
  local decoded, saved = pcall(vim.json.decode, table.concat(lines, "\n"))
  if not decoded or type(saved) ~= "table" then
    return {}
  end

  local connections = {}
  for _, conn in ipairs(saved) do
    local scheme, rest = tostring(conn.url or ""):match("^(%a+)://(.*)$")
    if scheme == "postgres" or scheme == "postgresql" or scheme == "mysql" then
      local userinfo, hostinfo = rest:match("^([^@]*)@(.*)$")
      hostinfo = hostinfo or rest
      userinfo = userinfo or ""
      local user, password = userinfo:match("^([^:]*):?(.*)$")
      local hostport, dbpart = hostinfo:match("^([^/]*)/?(.*)$")
      dbpart = dbpart or ""
      local dbname, query = dbpart:match("^([^%?]*)%??(.*)$")
      local host, port = (hostport or ""):match("^([^:]*):?(.*)$")
      host = host ~= "" and host or "127.0.0.1"

      if scheme == "mysql" then
        table.insert(connections, {
          alias = conn.name,
          driver = "mysql",
          dataSourceName = ("%s:%s@tcp(%s:%s)/%s"):format(user or "", password or "", host, port ~= "" and port or "3306", dbname or ""),
        })
      else
        local dsn = ("host=%s port=%s user=%s password=%s dbname=%s"):format(
          host, port ~= "" and port or "5432", user or "", password or "", dbname or ""
        )
        local sslmode = (query or ""):match("sslmode=([%w]+)")
        if sslmode then
          dsn = dsn .. " sslmode=" .. sslmode
        end
        table.insert(connections, { alias = conn.name, driver = "postgresql", dataSourceName = dsn })
      end
    elseif scheme == "sqlite" or scheme == "file" then
      table.insert(connections, { alias = conn.name, driver = "sqlite3", dataSourceName = rest })
    end
  end
  return connections
end

return {
  "neovim/nvim-lspconfig",
  event = "VeryLazy",
  dependencies = { "nanotee/sqls.nvim" },
  opts = {
    -- Faster LSP startup
    single_file_support = true,

    servers = {
      golangci_lint_ls = false,
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

      -- Go LSP — strict analyses to replace golangci-lint
      gopls = {
        settings = {
          gopls = {
            gofumpt = true,
            codelenses = {
              gc_details = false,
              generate = true,
              regenerate_cgo = true,
              run_govulncheck = true,
              test = true,
              tidy = true,
              upgrade_dependency = true,
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
              -- Bug detection
              nilness = true,
              shadow = false, -- expensive graph analysis
              unusedwrite = true,
              unusedvariable = true, -- quadratic on large dep graphs
              unreachable = false, -- expensive graph traversal
              lostcancel = true,
              loopclosure = true,
              atomicalign = true,
              copylocks = true,
              httpresponse = true,
              errorsas = true,
              testinggoroutine = true,
              appends = true,
              defers = true,
              slog = true,
              -- Code quality
              unusedparams = false, -- quadratic on large dep graphs
              unusedresult = true,
              printf = true,
              ifaceassert = true,
              stringintconv = true,
              bools = true,
              assign = true,
              directive = true,
              structtag = true,
              tests = true,
              timeformat = true,
              embeddirective = true,
              stdmethods = true,
              useany = true,
              sortslice = true,
              simplifyrange = true,
              simplifyslice = true,
              simplifycompositelit = true,
              infertypeargs = true,
              -- Quick fixes
              undeclaredname = true,
              fillreturns = true,
              nonewvars = true,
              fillstruct = true,
              stubmethods = true,
              -- Intentionally off (too noisy)
              fieldalignment = false,
            },
            diagnosticsTrigger = "Save",
            diagnosticsDelay = "500ms",
            vulncheck = "Imports",
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
            semanticTokens = false, -- expensive on large files
            staticcheck = false, -- 40+ analyzers; major perf hog on large repos
            experimentalPostfixCompletions = true,
          },
        },
      },

      -- SQL — schema-aware completion/hover via a real language server.
      -- Connections are read from sqmeow's connections.json (see sqls_connections
      -- above). sqls.nvim (dependency, on the runtimepath) supplies its own
      -- `lsp/sqls.lua` on_attach with `:SqlsSwitchConnection` / `:SqlsSwitchDatabase`
      -- to change which one completion targets, without restarting.
      sqls = {
        filetypes = { "sql", "mysql", "plsql" },
        settings = {
          sqls = {
            connections = sqls_connections(),
          },
        },
      },

      -- Docker
      dockerls = {},
      docker_compose_language_service = {},
    },
  },
}
