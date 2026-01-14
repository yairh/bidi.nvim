local M = {}
local render = require("bidi.render")

---@param opts table|nil
function M.setup(opts)
	M.enable()
end

function M.enable()
	render.enable()
end

function M.disable()
	render.disable()
end

function M.buf_enable()
	render.buf_enable(0)
end

function M.buf_disable()
	render.buf_disable(0)
end

return M
