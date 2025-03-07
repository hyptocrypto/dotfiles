local M = {}

local widgets = require("dap.ui.widgets")
local dap = require("dap")

local sidebar = nil

function M.toggleDebugUI()
  if not sidebar then
    sidebar = widgets.sidebar(widgets.scopes, { width = 50 })
  end
  sidebar.toggle()
  dap.repl.toggle()
end

return M
