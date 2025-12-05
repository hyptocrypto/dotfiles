-- Always grep from repository root
local function project_root()
  local buf = vim.api.nvim_buf_get_name(0)
  local start = (buf ~= "" and vim.fs.dirname(buf)) or vim.loop.cwd()
  if vim.system then
    local res = vim.system({ "git", "-C", start, "rev-parse", "--show-toplevel" }, { text = true }):wait()
    if res.code == 0 then
      local path = (res.stdout or ""):gsub("%s+$", "")
      if path ~= "" then
        return path
      end
    end
  else
    local out = vim.fn.system({ "git", "-C", start, "rev-parse", "--show-toplevel" })
    if vim.v.shell_error == 0 and type(out) == "string" and out ~= "" then
      return out:gsub("%s+$", "")
    end
  end
  local ok, util = pcall(require, "lazyvim.util")
  if ok then
    return util.root()
  end
  return vim.loop.cwd()
end

return {
  {
    "folke/snacks.nvim",
    keys = {
      {
        "<leader><space>",
        function()
          Snacks.picker.files()
        end,
        desc = "Find Files (Project)",
      },
      {
        "<leader>,",
        function()
          Snacks.picker.buffers()
        end,
        desc = "Buffers",
      },
      {
        "<leader>/",
        function()
          Snacks.picker.grep()
        end,
        desc = "Grep (Project)",
      },
      {
        "<leader>:",
        function()
          Snacks.picker.command_history()
        end,
        desc = "Command History",
      },
      {
        "<leader>n",
        function()
          Snacks.notifier.show_history()
        end,
        desc = "Notification History",
      },
      {
        "<leader>gd",
        function()
          Snacks.picker.git_diff({
            multi = false,
            win = {
              input = {
                keys = {
                  ["<Tab>"] = { "list_down", mode = { "i", "n" } },
                  ["<S-Tab>"] = { "list_up", mode = { "i", "n" } },
                },
              },
              list = {
                keys = {
                  ["<Tab>"] = { "list_down", mode = { "i", "n" } },
                  ["<S-Tab>"] = { "list_up", mode = { "i", "n" } },
                },
              },
            },
          })
        end,
        desc = "Git Diff (no multi)",
      },
    },

    opts = {
      -- Soft rounded styles for all Snacks components
      styles = {
        -- Notification style
        notification = {
          border = "rounded",
          wo = {
            wrap = true,
            winhighlight = "Normal:NormalFloat,FloatBorder:FloatBorder",
          },
        },
        -- Input prompt style
        input = {
          border = "rounded",
          wo = {
            winhighlight = "Normal:NormalFloat,FloatBorder:FloatBorder",
          },
        },
        -- Confirmation dialogs
        confirm = {
          border = "rounded",
          wo = {
            winhighlight = "Normal:NormalFloat,FloatBorder:FloatBorder",
          },
        },
        -- Float windows
        float = {
          border = "rounded",
          backdrop = false,
          wo = {
            winhighlight = "Normal:NormalFloat,FloatBorder:FloatBorder",
          },
        },
      },

      -- Notifier with rounded borders
      notifier = {
        timeout = 3000,
        style = "compact",
        icons = {
          error = " ",
          warn = " ",
          info = " ",
          debug = " ",
          trace = " ",
        },
      },

      -- Dashboard with softer look
      dashboard = {
        preset = {
          header = [[
 ╭───────────────────────────────────────╮
 │                                       │
 │            N E O V I M                │
 │                                       │
 ╰───────────────────────────────────────╯]],
        },
      },

      picker = {
        -- Custom layout without backdrop
        layouts = {
          default = {
            layout = {
              backdrop = false,
              width = 0.8,
              min_width = 120,
              height = 0.8,
              border = "rounded",
              title = "{source} {live}",
              title_pos = "center",
              box = "vertical",
              { win = "input", height = 1, border = "bottom" },
              {
                box = "horizontal",
                { win = "list", border = "none" },
                { win = "preview", width = 0.5, border = "left" },
              },
            },
          },
        },
        layout = "default",
        defaults = {
          cwd = project_root,
          hidden = true,
          ignored = true,
        },
        win = {
          input = {
            keys = {
              ["<S-Tab>"] = { "list_up", mode = { "i", "n" } },
              ["<Tab>"] = { "list_down", mode = { "i", "n" } },
            },
          },
          list = {
            keys = {
              ["<S-Tab>"] = { "list_up", mode = { "n" } },
              ["<Tab>"] = { "list_down", mode = { "n" } },
            },
          },
        },
        debug = {
          scores = false,
        },
        matcher = {
          frecency = true,
        },
        formatters = {},
        sources = {
          grep = {
            hidden = true,
            ignored = true,
            args = { "--hidden", "--no-ignore", "--no-ignore-global", "--no-ignore-parent" },
            exclude = {
              "**/*.log",
              "**/node_modules/**",
              "**/vendor/**",
              "**/__pycache__/**",
              "**/.pytest_cache/**",
              "**/target/**",
              "**/dist/**",
              "**/build/**",
              "**/.next/**",
              "**/.nuxt/**",
              "**/coverage/**",
              "**/.nyc_output/**",
              "**/.cache/**",
              "**/tmp/**",
              "**/temp/**",
              "**/.DS_Store",
              "**/Thumbs.db",
            },
          },
          files = {
            hidden = true,
            ignored = true,
            exclude = {
              "**/*.log",
              "**/node_modules/**",
              "**/.git/**",
              "**/vendor/**",
              "**/__pycache__/**",
              "**/.pytest_cache/**",
              "**/target/**",
              "**/dist/**",
              "**/build/**",
              "**/.next/**",
              "**/.nuxt/**",
              "**/coverage/**",
              "**/.nyc_output/**",
              "**/.cache/**",
              "**/tmp/**",
              "**/temp/**",
              "**/.DS_Store",
              "**/Thumbs.db",
            },
          },
        },
      },
      image = {
        enabled = true,
        doc = {
          inline = true,
          float = true,
          max_width = 50,
          max_height = 50,
        },
      },
    },
  },
}
