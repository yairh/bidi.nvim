local M = {}
local render = require("bidi.render")

---Setup the plugin
---@param opts table|nil Configuration options
function M.setup(opts)
	-- opts can configure things later
	M.enable()
end

---Enable bidi rendering globally
function M.enable()
	render.enable()
end

---Disable bidi rendering globally
function M.disable()
	render.disable()
end

---Enable bidi rendering for the current buffer
function M.buf_enable()
	render.buf_enable(0)
end

---Disable bidi rendering for the current buffer
function M.buf_disable()
	render.buf_disable(0)
end

return M
