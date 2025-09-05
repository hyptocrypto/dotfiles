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
    },

    opts = {
      picker = {
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
        },
        debug = {
          scores = false, -- show scores in the list
        },
        matcher = {
          frecency = true,
        },
        formatters = {
          -- file = {
          --   filename_first = true, -- display filename before the file path
          --   truncate = 80,
          -- },
        },
        sources = {
          grep = {
            hidden = true,
            ignored = true,
            args = { "--hidden", "--no-ignore", "--no-ignore-global", "--no-ignore-parent" },
            exclude = {
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
