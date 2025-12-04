return {
  "nvim-neo-tree/neo-tree.nvim",
  event = "VeryLazy",
  opts = {
    -- Soft rounded popup borders
    popup_border_style = "rounded",

    -- Softer icons
    default_component_configs = {
      indent = {
        indent_size = 2,
        padding = 1,
        with_markers = true,
        indent_marker = "│",
        last_indent_marker = "╰",
        highlight = "NeoTreeIndentMarker",
        with_expanders = true,
        expander_collapsed = "",
        expander_expanded = "",
        expander_highlight = "NeoTreeExpander",
      },
      icon = {
        folder_closed = "",
        folder_open = "",
        folder_empty = "",
        folder_empty_open = "",
        default = "",
      },
      modified = {
        symbol = "●",
        highlight = "NeoTreeModified",
      },
      git_status = {
        symbols = {
          added = "●",
          modified = "●",
          deleted = "●",
          renamed = "●",
          untracked = "○",
          ignored = "◌",
          unstaged = "○",
          staged = "●",
          conflict = "●",
        },
      },
    },

    -- Window appearance
    window = {
      position = "left",
      width = 35,
      mappings = {
        ["<space>"] = "none",
      },
    },

    filesystem = {
      filtered_items = {
        visible = true,
        show_hidden_count = true,
        hide_dotfiles = false,
        hide_gitignored = true,
        hide_by_name = {
          ".git",
          ".DS_Store",
          "thumbs.db",
          "node_modules",
          ".venv",
          "__pycache__",
          ".pytest_cache",
        },
        never_show = {
          ".git",
          ".DS_Store",
          "thumbs.db",
        },
      },
      -- Performance optimizations
      follow_current_file = {
        enabled = true,
        leave_dirs_open = false,
      },
      -- Avoid ENOENT errors from libuv when files/dirs are rapidly changing
      use_libuv_file_watcher = false,
    },
    -- Performance settings
    enable_git_status = true,
    enable_diagnostics = true,
    open_files_do_not_replace_types = { "terminal", "Trouble", "trouble", "qf", "Outline" },
  },
}
