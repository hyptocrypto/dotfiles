local dap = require("dap")
local utils = require("common")

return {
  "mfussenegger/nvim-dap",
  dependencies = {
    "leoluz/nvim-dap-go",
  },
  keys = {
    {
      "<Leader>dc",
      function()
        dap.run({
          name = "Attach Buffalo Dev",
          type = "go",
          request = "attach",
          mode = "remote",
          host = "127.0.0.1",
          port = 2345,
        })
        utils.toggleDebugUI()
      end,
      desc = "Attach Buffalo Dev (DAP)",
    },
    {
      "<Leader>dC",
      function()
        dap.continue()
      end,
      desc = "Continue (DAP)",
    },
    {
      "<Leader>dn",
      function()
        dap.step_over()
      end,
      desc = "Step Over (DAP)",
    },
    {
      "<Leader>di",
      function()
        dap.step_into()
      end,
      desc = "Step Into (DAP)",
    },
    {
      "<Leader>do",
      function()
        dap.step_out()
      end,
      desc = "Step Out (DAP)",
    },
    {
      "<Leader>du",
      function()
        utils.toggleDebugUI()
      end,
      desc = "Toggle Debug UI (DAP-UI)",
    },
  },
}
