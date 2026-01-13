local M = {}
local logic = require("bidi.logic")
local ns = vim.api.nvim_create_namespace("bidi")

local enabled = false

---Refresh the bidi rendering for a buffer
---@param bufnr integer|nil Buffer number (defaults to current buffer if nil/0)
function M.refresh_buffer(bufnr)
	if not enabled then return end
	if not bufnr or bufnr == 0 then
		bufnr = vim.api.nvim_get_current_buf()
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

---Enable the bidi rendering plugin
function M.enable()
	enabled = true
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

	-- Initial refresh for all visible buffers
	for _, win in ipairs(vim.api.nvim_list_wins()) do
		local bufnr = vim.api.nvim_win_get_buf(win)
		M.refresh_buffer(bufnr)
	end
end

---Disable the bidi rendering plugin
function M.disable()
	enabled = false
	pcall(vim.api.nvim_del_augroup_by_name, "BidiGroup")
	for _, bufnr in ipairs(vim.api.nvim_list_bufs()) do
		if vim.api.nvim_buf_is_loaded(bufnr) then
			vim.api.nvim_buf_clear_namespace(bufnr, ns, 0, -1)
		end
	end
end

---Check if bidi is enabled
---@return boolean
function M.is_enabled()
	return enabled
end

return M