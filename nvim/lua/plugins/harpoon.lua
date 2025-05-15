return {
  "ThePrimeagen/harpoon",
  branch = "harpoon2",
  dependencies = { "nvim-lua/plenary.nvim" },
  keys = {
    {
      "<leader>ha",
      function()
        require("harpoon"):list():add()
        vim.notify("File marked with Harpoon", vim.log.levels.INFO)
      end,
      desc = "Harpoon: Add file to list",
    },
    {
      "<leader>hh",
      function()
        local harpoon = require("harpoon")

        local function generate_harpoon_picker()
          local file_paths = {}
          for i, item in ipairs(harpoon:list().items) do
            local abs_path = vim.fn.fnamemodify(item.value, ":p")
            local lnum = item.context.row
            local col = item.context.col
            local line = ""

            if vim.fn.filereadable(abs_path) == 1 then
              local lines = vim.fn.readfile(abs_path)
              line = lines[lnum] or ""
            end

            table.insert(file_paths, {
              text = string.format("%d. %s %s", i, abs_path, line),
              file = abs_path,
              line = line,
              pos = { lnum, col },
              preview = {
                loc = true,
              },
            })
          end
          return file_paths
        end

        Snacks.picker({
          finder = generate_harpoon_picker,
          win = {
            input = {
              keys = {
                ["dd"] = { "harpoon_delete", mode = { "n", "x" } },
              },
            },
            list = {
              keys = {
                ["dd"] = { "harpoon_delete", mode = { "n", "x" } },
              },
            },
          },
          actions = {
            harpoon_delete = function(picker, item)
              local to_remove = item or picker:selected()
              table.remove(harpoon:list().items, to_remove.idx)
              picker:find({ refresh = true })
            end,
          },
        })
      end,
      desc = "Harpoon: Open file picker",
    },
  },
  config = function()
    local status_ok, harpoon = pcall(require, "harpoon")
    if not status_ok then
      return
    end
    harpoon:setup()
  end,
}
