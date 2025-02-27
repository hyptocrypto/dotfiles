return {
  "ibhagwan/fzf-lua",
  dependencies = { "nvim-tree/nvim-web-devicons", "uga-rosa/snacks.nvim" },
  config = function()
    local fzf = require("fzf-lua")

    fzf.setup({
      winopts = {
        preview = {
          layout = "vertical", -- Vertical split for preview
          default = "none", -- Disable default previewer
          border = "rounded",
        },
      },
      files = {
        previewer = function(filepath)
          local is_image = filepath:match("%.png$")
            or filepath:match("%.jpg$")
            or filepath:match("%.jpeg$")
            or filepath:match("%.gif$")
            or filepath:match("%.bmp$")
            or filepath:match("%.webp$")
          if is_image then
            -- Schedule snacks.nvim to prevent nil window issues
            return 'lua vim.schedule(function() require("snacks").display_image("' .. filepath .. '") end)'
          else
            return "bat --color=always --style=plain " .. filepath
          end
        end,
      },
    })
  end,
}
