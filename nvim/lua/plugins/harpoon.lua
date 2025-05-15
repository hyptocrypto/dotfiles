return {
  "ThePrimeagen/harpoon",
  branch = "harpoon2",
  dependencies = { "nvim-lua/plenary.nvim" },
  config = function()
    local status_ok, harpoon = pcall(require, "harpoon")
    if not status_ok then
      return
    end
    harpoon:setup()

    -- picker
    local function generate_harpoon_picker()
      local file_paths = {}
      for i, item in ipairs(harpoon:list().items) do
        local abs_path = vim.fn.fnamemodify(item.value, ":p")
        local lnum = item.context.row + 1
        local col = item.context.col
        local line = ""

        -- Read the preview line from the file (if readable)
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
    vim.keymap.set("n", "<leader>ha", function()
      harpoon:list():add()
      vim.notify("File marked with Harpoon", vim.log.levels.INFO)
    end)
    vim.keymap.set("n", "<leader>hh", function()
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
            picker:find({
              refresh = true, -- refresh picker after removing values
            })
          end,
        },
      })
    end)
  end,
}
