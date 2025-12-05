-- Helper to get project root (normalized, no trailing slash)
local function get_root()
  return vim.fn.fnamemodify(vim.fn.getcwd(), ":p"):gsub("/$", "")
end

-- Helper to check if path is at root (can't go higher)
local function is_at_root(dir)
  local root = get_root()
  local normalized_dir = vim.fn.fnamemodify(dir, ":p"):gsub("/$", "")
  return normalized_dir == root
end

return {
  -- Disable neo-tree
  { "nvim-neo-tree/neo-tree.nvim", enabled = false },

  -- Add oil.nvim
  {
    "stevearc/oil.nvim",
    dependencies = { "nvim-tree/nvim-web-devicons" },
    config = function()
      require("oil").setup({
        -- Oil will take over directory buffers (e.g. `vim .` or `:e src/`)
        default_file_explorer = true,

        -- Show hidden files
        view_options = {
          show_hidden = true,
          -- Hide certain files
          is_hidden_file = function(name, _)
            local hidden = {
              ".git",
              ".DS_Store",
              "thumbs.db",
              "node_modules",
              ".venv",
              "__pycache__",
              ".pytest_cache",
            }
            for _, pattern in ipairs(hidden) do
              if name == pattern then
                return true
              end
            end
            return false
          end,
        },

        -- Keymaps in oil buffer
        keymaps = {
          ["g?"] = "actions.show_help",
          ["<CR>"] = "actions.select",
          ["<C-v>"] = "actions.select_vsplit",
          ["<C-s>"] = "actions.select_split",
          ["<C-t>"] = "actions.select_tab",
          ["<C-p>"] = "actions.preview",
          ["<C-c>"] = "actions.close",
          ["<Esc>"] = "actions.close",
          ["<C-r>"] = "actions.refresh",
          -- Prevent navigating above root
          ["-"] = {
            callback = function()
              local oil = require("oil")
              local current_dir = oil.get_current_dir()
              if current_dir then
                if is_at_root(current_dir) then
                  vim.notify("Already at project root", vim.log.levels.INFO)
                else
                  require("oil.actions").parent.callback()
                end
              end
            end,
            desc = "Parent directory (bounded to root)",
          },
          ["gs"] = "actions.change_sort",
          ["gx"] = "actions.open_external",
          ["g."] = "actions.toggle_hidden",
          ["g\\"] = "actions.toggle_trash",
        },

        -- Use rounded floating window
        float = {
          padding = 2,
          max_width = 90,
          max_height = 30,
          border = "rounded",
          win_options = {
            winblend = 0,
          },
        },

        -- Skip confirmation for simple operations
        skip_confirm_for_simple_edits = true,

        -- Deleted files go to trash
        delete_to_trash = true,
      })
    end,
    keys = {
      {
        "<leader>e",
        function()
          require("oil").toggle_float(get_root())
        end,
        desc = "Toggle Oil (file explorer)",
      },
    },
  },
}
