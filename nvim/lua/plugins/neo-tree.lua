-- Function to toggle between Neo-tree, code file, and Dadbod UI
function ToggleNeoTreeOrCode()
  local neotree_winid = nil
  local code_winid = nil
  local dbui_winid = nil
  local dbout_winid = nil
  local current_winid = vim.fn.winnr()

  -- Iterate through all windows
  for winnr = 1, vim.fn.winnr("$") do
    local bufnr = vim.fn.winbufnr(winnr)
    local buftype = vim.bo[bufnr].buftype
    local filetype = vim.bo[bufnr].filetype

    if filetype == "neo-tree" then
      neotree_winid = winnr
    elseif filetype == "dbui" then
      dbui_winid = winnr
    elseif filetype == "dbout" then
      dbout_winid = winnr
    elseif buftype == "" then
      code_winid = winnr
    end
  end

  -- Cycle: code -> neo-tree -> dbui -> code
  if current_winid == code_winid then
    if neotree_winid then
      vim.cmd(neotree_winid .. "wincmd w")
    elseif dbui_winid then
      vim.cmd(dbui_winid .. "wincmd w")
    end
  elseif current_winid == neotree_winid then
    if dbui_winid then
      vim.cmd(dbui_winid .. "wincmd w")
    elseif code_winid then
      vim.cmd(code_winid .. "wincmd w")
    end
  elseif current_winid == dbui_winid then
    if code_winid then
      vim.cmd(code_winid .. "wincmd w")
    elseif neotree_winid then
      vim.cmd(neotree_winid .. "wincmd w")
    end
  elseif current_winid == dbout_winid then
    if code_winid then
      vim.cmd(code_winid .. "wincmd w")
    end
  else
    -- Fallback: go to code window if not in any known window
    if code_winid then
      vim.cmd(code_winid .. "wincmd w")
    end
  end
end

vim.keymap.set("n", "<leader>t", ToggleNeoTreeOrCode, { desc = "Toggle between Neo-tree and code file" })

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
      -- icon = {
      --   folder_closed = "",
      --   folder_open = "",
      --   folder_empty = "",
      --   folder_empty_open = "",
      --   default = "",
      -- },
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
