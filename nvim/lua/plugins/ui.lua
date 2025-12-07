-- Soft & Rounded UI Enhancements
return {
  -- Which-key with rounded borders
  {
    "folke/which-key.nvim",
    opts = {
      win = {
        border = "rounded",
        padding = { 1, 2 },
      },
      icons = {
        breadcrumb = "»",
        separator = "›",
        group = "+ ",
      },
    },
  },

  -- Noice with rounded borders for cmdline and popups
  {
    "folke/noice.nvim",
    opts = {
      presets = {
        bottom_search = true,
        command_palette = true,
        long_message_to_split = true,
        lsp_doc_border = true, -- Add border to LSP docs
      },
      views = {
        -- Rounded cmdline popup
        cmdline_popup = {
          border = {
            style = "rounded",
            padding = { 0, 1 },
          },
        },
        -- Rounded popup menu
        popupmenu = {
          border = {
            style = "rounded",
            padding = { 0, 1 },
          },
        },
        -- Rounded hover docs
        hover = {
          border = {
            style = "rounded",
            padding = { 0, 1 },
          },
        },
      },
      lsp = {
        override = {
          ["vim.lsp.util.convert_input_to_markdown_lines"] = true,
          ["vim.lsp.util.stylize_markdown"] = true,
          ["cmp.entry.get_documentation"] = true,
        },
        hover = {
          enabled = true,
        },
        signature = {
          enabled = true,
        },
      },
    },
  },

  -- Trouble with softer appearance
  {
    "folke/trouble.nvim",
    opts = {
      icons = {
        indent = {
          middle = "│ ",
          last = "╰─",
          top = "╭─",
          ws = "  ",
        },
        folder_closed = " ",
        folder_open = " ",
        kinds = {
          Array = " ",
          Boolean = " ",
          Class = " ",
          Constant = " ",
          Constructor = " ",
          Enum = " ",
          EnumMember = " ",
          Event = " ",
          Field = " ",
          File = " ",
          Function = " ",
          Interface = " ",
          Key = " ",
          Method = " ",
          Module = " ",
          Namespace = " ",
          Null = " ",
          Number = " ",
          Object = " ",
          Operator = " ",
          Package = " ",
          Property = " ",
          String = " ",
          Struct = " ",
          TypeParameter = " ",
          Variable = " ",
        },
      },
    },
  },

  -- Mason with rounded borders
  {
    "mason-org/mason.nvim",
    opts = {
      ui = {
        border = "rounded",
        icons = {
          package_installed = "●",
          package_pending = "○",
          package_uninstalled = "○",
        },
      },
    },
  },

  -- Lazy.nvim UI with rounded borders
  {
    "folke/lazy.nvim",
    opts = {
      ui = {
        border = "rounded",
        icons = {
          cmd = " ",
          config = " ",
          event = " ",
          ft = " ",
          init = " ",
          import = " ",
          keys = " ",
          lazy = "󰒲 ",
          loaded = "●",
          not_loaded = "○",
          plugin = " ",
          runtime = " ",
          require = "󰢱 ",
          source = " ",
          start = " ",
          task = " ",
          list = {
            "●",
            "›",
            "›",
            "›",
          },
        },
      },
    },
  },

  -- Indent blankline with softer appearance
  {
    "lukas-reineke/indent-blankline.nvim",
    opts = {
      indent = {
        char = "│",
        tab_char = "│",
      },
      scope = {
        char = "│",
        show_start = false,
        show_end = false,
      },
    },
  },

  -- Gitsigns with softer symbols
  {
    "lewis6991/gitsigns.nvim",
    opts = {
      signs = {
        add = { text = "│" },
        change = { text = "│" },
        delete = { text = "│" },
        topdelete = { text = "│" },
        changedelete = { text = "│" },
        untracked = { text = "│" },
      },
      signs_staged = {
        add = { text = "│" },
        change = { text = "│" },
        delete = { text = "│" },
        topdelete = { text = "│" },
        changedelete = { text = "│" },
      },
    },
  },

  -- Lualine with rounded separators (optional - softer look)
  {
    "nvim-lualine/lualine.nvim",
    opts = function(_, opts)
      opts.options = vim.tbl_deep_extend("force", opts.options or {}, {
        component_separators = { left = "│", right = "│" },
        section_separators = { left = "", right = "" },
      })
      return opts
    end,
  },
}
