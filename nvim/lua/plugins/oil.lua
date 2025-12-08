-- Helper function to get project root
local function get_root_dir()
  local buf = vim.api.nvim_buf_get_name(0)
  local start = (buf ~= "" and vim.fs.dirname(buf)) or vim.loop.cwd()

  -- Try to find git root
  local result = vim.fn.systemlist("git -C " .. vim.fn.shellescape(start) .. " rev-parse --show-toplevel 2>/dev/null")
  if vim.v.shell_error == 0 and result[1] and result[1] ~= "" then
    return result[1]
  end

  -- Fallback to cwd
  return vim.loop.cwd()
end

local function parent_limited()
  local root = get_root_dir()
  local current_dir = require("oil").get_current_dir()

  -- Normalize paths (remove trailing slash)
  local function normalize(p)
    return p and p:gsub("/+$", "")
  end

  root = normalize(root)
  current_dir = normalize(current_dir)

  -- If already at root, do nothing
  if current_dir == root then
    return
  end

  -- Otherwise call original parent action
  return require("oil.actions").parent.callback()
end

return {
  {
    "stevearc/oil.nvim",
    dependencies = { "nvim-tree/nvim-web-devicons" },
    lazy = false,
    config = function()
      require("oil").setup({
        -- Oil will take over directory buffers (e.g. `nvim .` or `:e src/`)
        default_file_explorer = true,

        -- Columns to display
        columns = {
          "icon",
        },

        -- Buffer-local options for oil buffers
        buf_options = {
          buflisted = false,
          bufhidden = "hide",
        },

        -- Window-local options for oil buffers
        win_options = {
          wrap = false,
          signcolumn = "no",
          cursorcolumn = false,
          foldcolumn = "0",
          spell = false,
          list = false,
          conceallevel = 3,
          concealcursor = "nvic",
        },

        -- Skip confirmation for simple operations
        skip_confirm_for_simple_edits = true,

        -- Selecting a new/moved/renamed file will prompt to save first
        prompt_save_on_select_new_entry = true,

        -- Keymaps in oil buffer
        keymaps = {
          ["g?"] = "actions.show_help",
          ["<CR>"] = "actions.select",
          ["<S-CR>"] = "actions.parent",
          ["<C-v>"] = "actions.select_vsplit",
          ["<C-s>"] = "actions.select_split",
          ["<C-t>"] = "actions.select_tab",
          ["<C-p>"] = "actions.preview",
          ["q"] = "actions.close",
          ["<C-c>"] = "actions.close",
          ["<C-r>"] = "actions.refresh",
          ["-"] = parent_limited,
          ["_"] = "actions.open_cwd",
          ["`"] = "actions.cd",
          ["~"] = "actions.tcd",
          ["gs"] = "actions.change_sort",
          ["gx"] = "actions.open_external",
          ["g."] = "actions.toggle_hidden",
          ["g\\"] = "actions.toggle_trash",
        },

        -- Set to false to disable all keymaps
        use_default_keymaps = false,

        view_options = {
          -- Show hidden files
          show_hidden = true,
          -- Hide certain files
          is_always_hidden = function(name, _)
            return name == ".." or name == ".git" or name == ".DS_Store"
          end,
        },

        -- Floating window configuration
        float = {
          padding = 2,
          max_width = 120,
          max_height = 40,
          border = "rounded",
          win_options = {
            winblend = 0,
          },
        },

        -- Preview window configuration
        preview = {
          max_width = 0.9,
          min_width = { 40, 0.4 },
          width = nil,
          max_height = 0.9,
          min_height = { 5, 0.1 },
          height = nil,
          border = "rounded",
          win_options = {
            winblend = 0,
          },
        },

        -- Progress window configuration
        progress = {
          max_width = 0.9,
          min_width = { 40, 0.4 },
          width = nil,
          max_height = { 10, 0.9 },
          min_height = { 5, 0.1 },
          height = nil,
          border = "rounded",
          minimized_border = "rounded",
          win_options = {
            winblend = 0,
          },
        },
      })
    end,
    keys = {
      {
        "<leader>e",
        function()
          require("oil").toggle_float(get_root_dir())
        end,
        desc = "Oil (project root)",
      },
      {
        "-",
        function()
          require("oil").open()
        end,
        desc = "Oil (parent directory)",
      },
    },
  },
  -- Replace the default LazyVim file explorer (neo-tree) with Oil
  {
    "nvim-neo-tree/neo-tree.nvim",
    enabled = false,
  },
}
