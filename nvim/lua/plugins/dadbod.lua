local db_tab = nil
local saved_dbout_lines = nil
local last_sql_buf = nil

vim.api.nvim_create_autocmd("FileType", {
  pattern = "dbout",
  callback = function(ev)
    vim.schedule(function()
      if not vim.api.nvim_buf_is_valid(ev.buf) then
        return
      end
      vim.bo[ev.buf].bufhidden = "hide"

      -- Close any windows showing a different (stale) dbout buffer
      for _, win in ipairs(vim.api.nvim_list_wins()) do
        if vim.api.nvim_win_is_valid(win) then
          local buf = vim.api.nvim_win_get_buf(win)
          if buf ~= ev.buf and vim.api.nvim_buf_is_valid(buf) and vim.bo[buf].filetype == "dbout" then
            vim.api.nvim_win_close(win, true)
          end
        end
      end
    end)
  end,
})

-- Returns the most recently created dbout buffer (highest buf number)
local function find_dbout_buf()
  local latest = nil
  for _, buf in ipairs(vim.api.nvim_list_bufs()) do
    if vim.api.nvim_buf_is_valid(buf) and vim.bo[buf].filetype == "dbout" then
      latest = buf
    end
  end
  return latest
end

local function save_db_state()
  -- Save the dbout content from the buffer currently visible in a window,
  -- which is always the most recent query result
  if db_tab and vim.api.nvim_tabpage_is_valid(db_tab) then
    for _, win in ipairs(vim.api.nvim_tabpage_list_wins(db_tab)) do
      local buf = vim.api.nvim_win_get_buf(win)
      if vim.api.nvim_buf_is_valid(buf) and vim.bo[buf].filetype == "dbout" then
        saved_dbout_lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
        break
      end
    end

    -- Save which SQL script the user was editing
    for _, win in ipairs(vim.api.nvim_tabpage_list_wins(db_tab)) do
      local buf = vim.api.nvim_win_get_buf(win)
      if vim.api.nvim_buf_is_valid(buf) and vim.bo[buf].filetype == "sql" then
        last_sql_buf = buf
        break
      end
    end
  end
end

local function get_or_restore_dbout()
  local buf = find_dbout_buf()
  if buf then
    return buf
  end
  if saved_dbout_lines and #saved_dbout_lines > 0 then
    buf = vim.api.nvim_create_buf(false, true)
    vim.api.nvim_buf_set_lines(buf, 0, -1, false, saved_dbout_lines)
    vim.bo[buf].filetype = "dbout"
    vim.bo[buf].buftype = "nofile"
    vim.bo[buf].modifiable = false
    vim.bo[buf].bufhidden = "hide"
    return buf
  end
  return nil
end

local function show_dbout()
  local dbout = get_or_restore_dbout()
  if dbout then
    vim.cmd("botright split")
    vim.api.nvim_win_set_buf(0, dbout)
    vim.cmd("resize 15")
    vim.cmd("wincmd k")
  end
end

local function find_connected_sql_buf()
  for _, buf in ipairs(vim.api.nvim_list_bufs()) do
    if vim.api.nvim_buf_is_valid(buf)
      and vim.api.nvim_buf_is_loaded(buf)
      and vim.bo[buf].filetype == "sql"
      and vim.b[buf].db
      and vim.b[buf].db ~= "" then
      return buf
    end
  end
  return nil
end

local function get_sql_buf_to_restore()
  if last_sql_buf
    and vim.api.nvim_buf_is_valid(last_sql_buf)
    and vim.api.nvim_buf_is_loaded(last_sql_buf)
    and vim.b[last_sql_buf].db
    and vim.b[last_sql_buf].db ~= "" then
    return last_sql_buf
  end
  return find_connected_sql_buf()
end

-- Navigate the DBUI tree to open "New query" under the first connection
local function open_query_via_dbui()
  local dbui_buf = vim.api.nvim_get_current_buf()
  if vim.bo[dbui_buf].filetype ~= "dbui" then
    return
  end

  local lines = vim.api.nvim_buf_get_lines(dbui_buf, 0, -1, false)
  if #lines == 0 then
    return
  end

  local cr = vim.api.nvim_replace_termcodes("<CR>", true, true, true)

  for i, line in ipairs(lines) do
    if line:match("New query") then
      vim.api.nvim_win_set_cursor(0, { i, 0 })
      vim.api.nvim_feedkeys(cr, "n", false)
      vim.defer_fn(show_dbout, 150)
      return
    end
  end

  vim.api.nvim_win_set_cursor(0, { 1, 0 })
  vim.api.nvim_feedkeys(cr, "n", false)

  vim.defer_fn(function()
    local updated = vim.api.nvim_buf_get_lines(dbui_buf, 0, -1, false)
    for i, line in ipairs(updated) do
      if line:match("New query") then
        vim.api.nvim_win_set_cursor(0, { i, 0 })
        vim.api.nvim_feedkeys(cr, "n", false)
        vim.defer_fn(show_dbout, 150)
        return
      end
    end
  end, 150)
end

local function toggle_db_mode()
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
  db_tab = vim.api.nvim_get_current_tabpage()
  vim.cmd("DBUI")

  vim.defer_fn(function()
    if not db_tab or not vim.api.nvim_tabpage_is_valid(db_tab) then
      return
    end

    local sql_buf = get_sql_buf_to_restore()
    if sql_buf then
      vim.cmd("wincmd l")
      vim.api.nvim_win_set_buf(0, sql_buf)
      show_dbout()
      return
    end

    open_query_via_dbui()
  end, 200)
end

return {
  {
    "kristijanhusak/vim-dadbod-ui",
    keys = {
      { "<leader>DD", toggle_db_mode, desc = "Toggle DB Mode" },
      { "<leader>D", false },
    },
  },
}
