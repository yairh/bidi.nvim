local M = {}
local render = require("bidi.render")

---Setup the plugin
---@param opts table|nil Configuration options
function M.setup(opts)
	-- opts can configure things later
	render.enable()
end

return M

