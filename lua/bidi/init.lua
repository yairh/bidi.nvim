local M = {}
local render = require("bidi.render")

---Setup the plugin
---@param opts table|nil Configuration options
function M.setup(opts)
	-- opts can configure things later
	M.enable()
end

---Enable bidi rendering
function M.enable()
	render.enable()
end

---Disable bidi rendering
function M.disable()
	render.disable()
end

return M