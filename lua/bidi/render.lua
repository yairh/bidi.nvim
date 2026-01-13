local M = {}
local logic = require("bidi.logic")
local ns = vim.api.nvim_create_namespace("bidi")

local global_enabled = false

---Check if bidi is enabled for a specific buffer
---@param bufnr integer
---@return boolean
local function is_buf_enabled(bufnr)
	-- Check buffer-local variable first.
	local ok, val = pcall(vim.api.nvim_buf_get_var, bufnr, "bidi_enabled")
	if ok then
		return val
	end
	return global_enabled
end

---Refresh the bidi rendering for a buffer
---@param bufnr integer|nil Buffer number (defaults to current buffer if nil/0)
function M.refresh_buffer(bufnr)
	if not bufnr or bufnr == 0 then
		bufnr = vim.api.nvim_get_current_buf()
	end

	if not is_buf_enabled(bufnr) then
		return
	end

	-- Check window option 'rightleft'
	local is_rightleft = false
	if vim.api.nvim_get_current_buf() == bufnr then
		is_rightleft = vim.wo.rightleft
	end

	-- Clear existing marks
	vim.api.nvim_buf_clear_namespace(bufnr, ns, 0, -1)

	local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
	for i, line in ipairs(lines) do
		local processed
		if is_rightleft then
			processed = logic.process_line(line, logic.Dir.RTL)
		else
			processed = logic.process_line(line, logic.Dir.LTR)
		end

		if processed ~= line then
			vim.api.nvim_buf_set_extmark(bufnr, ns, i - 1, 0, {
				virt_text = { { processed } },
				virt_text_pos = "overlay",
				hl_mode = "combine",
			})
		end
	end
end

---Internal function to setup autocmds
local function setup_autocmds()
	local group = vim.api.nvim_create_augroup("BidiGroup", { clear = true })
	vim.api.nvim_create_autocmd({ "TextChanged", "TextChangedI", "BufWinEnter", "OptionSet" }, {
		group = group,
		callback = function(args)
			if args.event == "OptionSet" and args.match ~= "rightleft" then
				return
			end
			M.refresh_buffer(args.buf)
		end
	})
end

---Enable the bidi rendering plugin globally
function M.enable()
	global_enabled = true
	setup_autocmds()
	for _, win in ipairs(vim.api.nvim_list_wins()) do
		local bufnr = vim.api.nvim_win_get_buf(win)
		M.refresh_buffer(bufnr)
	end
end

---Disable the bidi rendering plugin globally
function M.disable()
	global_enabled = false
	-- We keep the augroup so buffer-local overrides still work.
	-- We clear namespaces for buffers that fall back to the global state (false).
	for _, bufnr in ipairs(vim.api.nvim_list_bufs()) do
		if vim.api.nvim_buf_is_loaded(bufnr) then
			local ok, val = pcall(vim.api.nvim_buf_get_var, bufnr, "bidi_enabled")
			if not ok or not val then
				vim.api.nvim_buf_clear_namespace(bufnr, ns, 0, -1)
			end
		end
	end
end

---Enable bidi for the current buffer
---@param bufnr integer|nil
function M.buf_enable(bufnr)
	if not bufnr or bufnr == 0 then bufnr = vim.api.nvim_get_current_buf() end
	vim.api.nvim_buf_set_var(bufnr, "bidi_enabled", true)

	-- Ensure autocmds are active
	if pcall(vim.api.nvim_get_autocmds, { group = "BidiGroup" }) then
		local cmds = vim.api.nvim_get_autocmds({ group = "BidiGroup" })
		if #cmds == 0 then
			setup_autocmds()
		end
	else
		setup_autocmds()
	end

	M.refresh_buffer(bufnr)
end

---Disable bidi for the current buffer
---@param bufnr integer|nil
function M.buf_disable(bufnr)
	if not bufnr or bufnr == 0 then bufnr = vim.api.nvim_get_current_buf() end
	vim.api.nvim_buf_set_var(bufnr, "bidi_enabled", false)
	vim.api.nvim_buf_clear_namespace(bufnr, ns, 0, -1)
end

---Check if bidi is enabled globally
---@return boolean
function M.is_enabled()
	return global_enabled
end

return M