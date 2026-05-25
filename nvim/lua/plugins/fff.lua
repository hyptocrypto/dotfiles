-- Same project-root helper used by the old snacks picker
local function project_root()
  local buf = vim.api.nvim_buf_get_name(0)
  local start = (buf ~= "" and vim.fs.dirname(buf)) or vim.uv.cwd()
  local res = vim.system({ "git", "-C", start, "rev-parse", "--show-toplevel" }, { text = true }):wait()
  if res.code == 0 then
    local path = (res.stdout or ""):gsub("%s+$", "")
    if path ~= "" then
      return path
    end
  end
  return vim.uv.cwd()
end

return {
  {
    "dmtrKovalenko/fff.nvim",
    build = function()
      require("fff.download").download_or_build_binary()
    end,
    lazy = false,
    opts = {
      layout = {
        prompt_position = "top",
        preview_position = "right",
        preview_size = 0.5,
        width = 0.8,
        height = 0.8,
      },
      frecency = {
        enabled = true,
      },
      keymaps = {
        move_down = { "<Down>", "<C-n>", "<Tab>" },
        move_up = { "<Up>", "<C-p>", "<S-Tab>" },
        toggle_select = "<C-Space>",
        cycle_grep_modes = "<C-g>",
      },
    },
    keys = {
      {
        "<leader><space>",
        function()
          require("fff").find_files_in_dir(project_root())
        end,
        desc = "Find Files (Project)",
      },
      {
        "<leader>/",
        function()
          require("fff").live_grep()
        end,
        desc = "Grep (Project)",
      },
      {
        "<leader>fc",
        function()
          require("fff").live_grep({ query = vim.fn.expand("<cword>") })
        end,
        desc = "FFF: Search Word Under Cursor",
      },
      {
        "<leader>fz",
        function()
          require("fff").live_grep({ grep = { modes = { "fuzzy", "plain" } } })
        end,
        desc = "FFF: Fuzzy Grep",
      },
    },
  },
}
