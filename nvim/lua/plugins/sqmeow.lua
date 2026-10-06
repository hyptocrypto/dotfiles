local db_tab = nil
local last_scratch_buf = nil

vim.api.nvim_create_autocmd("TabClosed", {
  callback = function()
    if db_tab and not vim.api.nvim_tabpage_is_valid(db_tab) then
      db_tab = nil
    end
  end,
})

local function is_scratchpad_buf(buf)
  return vim.api.nvim_buf_is_valid(buf) and vim.b[buf].sqmeow_editor == true
end

-- Remember whichever scratchpad buffer was open in DB mode, so toggling back
-- on reuses it instead of leaving a stray empty buffer around.
local function save_db_state()
  if not db_tab or not vim.api.nvim_tabpage_is_valid(db_tab) then
    return
  end
  for _, win in ipairs(vim.api.nvim_tabpage_list_wins(db_tab)) do
    local buf = vim.api.nvim_win_get_buf(win)
    if is_scratchpad_buf(buf) then
      last_scratch_buf = buf
      break
    end
  end
end

local function find_scratch_buf()
  if last_scratch_buf and is_scratchpad_buf(last_scratch_buf) and vim.api.nvim_buf_is_loaded(last_scratch_buf) then
    return last_scratch_buf
  end
  for _, buf in ipairs(vim.api.nvim_list_bufs()) do
    if vim.api.nvim_buf_is_loaded(buf) and is_scratchpad_buf(buf) then
      return buf
    end
  end
  return nil
end

local function toggle_sqmeow()
  if db_tab and not vim.api.nvim_tabpage_is_valid(db_tab) then
    db_tab = nil
  end

  if db_tab then
    if #vim.api.nvim_list_tabpages() <= 1 then
      vim.notify("DB Mode is the only tab — open a file first", vim.log.levels.WARN)
      return
    end
    save_db_state()
    vim.api.nvim_set_current_tabpage(db_tab)
    vim.cmd("tabclose")
    db_tab = nil
    return
  end

  vim.cmd("tabnew")
  -- Wipe the throwaway blank buffer `tabnew` creates once it's hidden, so
  -- toggling repeatedly doesn't pile up empty [No Name] buffers.
  vim.bo[vim.api.nvim_get_current_buf()].bufhidden = "wipe"

  local scratch = find_scratch_buf()
  if scratch then
    vim.api.nvim_win_set_buf(0, scratch)
  else
    local pads = require("sqmeow.ui.editor").list()
    if pads[1] then
      require("sqmeow.ui.editor").open_path(pads[1].path)
    end
  end

  db_tab = vim.api.nvim_get_current_tabpage()
  vim.cmd("Sqmeow")
end

return {
  {
    "2giosangmitom/sqmeow.nvim",
    dependencies = { "MunifTanjim/nui.nvim" },
    version = "*",
    build = function()
      require("sqmeow").install()
    end,
    opts = {
      ui = {
        persist_session = true,
      },
    },
    cmd = "Sqmeow",
    keys = {
      { "<leader>DD", toggle_sqmeow, desc = "Toggle DB Mode" },
      { "<leader>Da", "<cmd>Sqmeow add<cr>", desc = "DB Add Connection" },
      { "<leader>Ds", "<cmd>Sqmeow scratch<cr>", desc = "DB New Scratchpad" },
      { "<leader>Dc", "<cmd>Sqmeow cancel<cr>", desc = "DB Cancel Query" },
    },
  },
}
