local M = {}
local render = require("bidi.render")

function M.setup(opts)
  -- opts can configure things later
  render.enable()
  print("bidi.nvim: Enabled bidirectional support (prototype)")
end

return M