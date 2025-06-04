return {
  "tomasky/bookmarks.nvim",
  event = "VeryLazy",
  config = function()
    require("bookmarks").setup({
      save_file = vim.fn.expand("$HOME/.bookmarks"),
      keywords = {
        ["@t"] = "☑️ ",
        ["@w"] = "⚠️ ",
        ["@f"] = "⛏ ",
        ["@n"] = " ",
      },
    })
  end,
  keys = {
    {
      "<leader>ha",
      function()
        require("bookmarks").bookmark_toggle()
        require("bookmarks").saveBookmarks()
        vim.notify("Bookmark toggled", vim.log.levels.INFO)
      end,
      desc = "Bookmark: Toggle",
    },
    {
      "<leader>hi",
      function()
        require("bookmarks").bookmark_ann()
      end,
      desc = "Bookmark: Annotate",
    },
    {
      "<leader>hd",
      function()
        require("bookmarks").bookmark_clean()
      end,
      desc = "Bookmark: Clean current buffer",
    },
    {
      "<leader>hh",
      function()
        local bookmarks = require("bookmarks")
        local file = vim.fn.expand("$HOME/.bookmarks")
        local ok, content = pcall(vim.fn.readfile, file)
        if not ok then
          vim.notify("Failed to read bookmarks file", vim.log.levels.ERROR)
          return
        end

        local parsed = vim.fn.json_decode(table.concat(content, "\n"))
        if not parsed or not parsed.data then
          vim.notify("No bookmarks found", vim.log.levels.INFO)
          return
        end

        local items = {}
        local idx = 0

        for filepath, marks in pairs(parsed.data) do
          local abs_path = vim.fn.fnamemodify(filepath, ":p")
          for line_str, mark in pairs(marks) do
            local line_num = tonumber(line_str)
            if line_num then
              local line_text = ""
              if vim.fn.filereadable(abs_path) == 1 then
                local lines = vim.fn.readfile(abs_path)
                line_text = lines[line_num + 1] or ""
              end

              idx = idx + 1
              table.insert(items, {
                idx = idx,
                text = string.format("%d. %s:%d %s", idx, abs_path, line_num + 1, line_text),
                file = abs_path,
                pos = { line_num + 1, 0 },
                preview = {
                  loc = true,
                },
              })
            end
          end
        end

        Snacks.picker({
          finder = function()
            return items
          end,
          win = {
            input = {
              keys = {
                ["dd"] = { "bookmark_delete", mode = { "n", "x" } },
              },
            },
            list = {
              keys = {
                ["dd"] = { "bookmark_delete", mode = { "n", "x" } },
              },
            },
          },
          actions = {
            bookmark_delete = function(picker, item)
              local selected = item or picker:selected()
              local filepath = selected.file
              local line = selected.pos[1] - 1
              local data = vim.fn.json_decode(table.concat(vim.fn.readfile(file), "\n"))

              if data and data.data and data.data[filepath] and data.data[filepath][tostring(line)] then
                data.data[filepath][tostring(line)] = nil
                if vim.tbl_isempty(data.data[filepath]) then
                  data.data[filepath] = nil
                end
                local new_json = vim.fn.json_encode(data)
                vim.fn.writefile(vim.split(new_json, "\n"), file)
                picker:find({ refresh = true })
              end
            end,
          },
        })
      end,
      desc = "Bookmark: Open picker",
    },
    {
      "<leader>hD",
      function()
        require("bookmarks").bookmark_clear_all()
      end,
      desc = "Bookmark: Clear all",
    },
  },
}
