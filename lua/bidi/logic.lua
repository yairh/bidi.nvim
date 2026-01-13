local M = {}

---@enum Dir
M.Dir = {
	LTR = 'L',
	RTL = 'R',
	NEUTRAL = 'N'
}

---Check if a character is Hebrew (Strong R)
---@param char string
---@return boolean
function M.is_hebrew(char)
	local codepoint = vim.fn.char2nr(char)
	return (codepoint >= 0x0590 and codepoint <= 0x05FF)
end

---Check if a character is Neutral (Space, Punctuation, Symbols)
---Assumes non-ASCII multi-byte characters are NOT neutral (defaulting to LTR usually, unless Hebrew)
---@param char string
---@return boolean
function M.is_neutral(char)
	if #char > 1 then return false end
	local b = string.byte(char)

	-- Digits (0-9) are Strong LTR (48-57)
	if b >= 48 and b <= 57 then return false end
	-- Uppercase Letters (A-Z) are Strong LTR (65-90)
	if b >= 65 and b <= 90 then return false end
	-- Lowercase Letters (a-z) are Strong LTR (97-122)
	if b >= 97 and b <= 122 then return false end

	-- All other ASCII characters (Space, Punctuation, Control) are Neutral
	return true
end

---Determine the paragraph direction based on the first strong character
---@param items table List of {char, type} items
---@return Dir
function M.detect_paragraph_direction(items)
	for _, item in ipairs(items) do
		if item.type == M.Dir.LTR or item.type == M.Dir.RTL then
			return item.type
		end
	end
	return M.Dir.LTR -- Default to LTR if no strong characters found
end

---Reverse a list of items in place
---@param list table
---@param start_idx integer
---@param end_idx integer
local function reverse_slice(list, start_idx, end_idx)
	while start_idx < end_idx do
		list[start_idx], list[end_idx] = list[end_idx], list[start_idx]
		start_idx = start_idx + 1
		end_idx = end_idx - 1
	end
end

---Reorder runs based on their embedding levels (Simplified UBA L2)
---@param runs table List of {text=..., level=...}
---@return table The reordered list of runs
local function reorder_runs(runs)
	if #runs == 0 then return runs end

	local max_level = 0
	local min_level = runs[1].level
	for _, run in ipairs(runs) do
		if run.level > max_level then max_level = run.level end
		if run.level < min_level then min_level = run.level end
	end

	-- Reverse runs for each level from max down to lowest odd level (UBA L2)
	local stop_level = (min_level % 2 == 1) and min_level or (min_level + 1)
	for level = max_level, stop_level, -1 do
		local i = 1
		while i <= #runs do
			if runs[i].level >= level then
				local start = i
				while i <= #runs and runs[i].level >= level do
					i = i + 1
				end
				local end_idx = i - 1
				reverse_slice(runs, start, end_idx)
			else
				i = i + 1
			end
		end
	end
	return runs
end

---Process a line of text, reordering bidirectional segments for visual display
---@param line string The input line of text
---@param view_direction Dir The direction of the view/window
---@return string The processed line
function M.process_line(line, view_direction)
	local items = {}

	-- 1. Parse and classify characters
	for char in string.gmatch(line, "[%z\1-\127\194-\244][\128-\191]*") do
		local type = M.Dir.LTR -- Default to Strong LTR (includes Numbers, Latin, non-Hebrew Unicode)

		if M.is_hebrew(char) then
			type = M.Dir.RTL
		elseif M.is_neutral(char) then
			type = M.Dir.NEUTRAL
		end

		table.insert(items, { char = char, type = type })
	end

	-- 2. Detect Paragraph Direction (Base Direction)
	local para_direction = M.detect_paragraph_direction(items)
	local base_level = (para_direction == M.Dir.RTL) and 1 or 0

	-- 3. Resolve Neutrals
	-- Neutrals take the direction of surrounding strong types.
	-- If mixed or boundary -> default to para_direction (Base Direction).
	for i, item in ipairs(items) do
		if item.type == M.Dir.NEUTRAL then
			local prev_strong = para_direction
			for j = i - 1, 1, -1 do
				if items[j].type ~= M.Dir.NEUTRAL then
					prev_strong = items[j].type
					break
				end
			end

			local next_strong = para_direction
			for j = i + 1, #items do
				if items[j].type ~= M.Dir.NEUTRAL then
					next_strong = items[j].type
					break
				end
			end

			if prev_strong == next_strong then
				item.resolved = prev_strong
			else
				item.resolved = para_direction
			end
		else
			item.resolved = item.type
		end
	end

	-- 4. Assign Levels and Group into Runs
	local runs = {}
	local current_run_chars = {}
	local current_level = nil

	local function get_embedding_level(direction, base)
		if direction == M.Dir.RTL then
			return 1 -- RTL text is always level 1 (simplified)
		else
			-- LTR text: Level 0 if Base is 0, Level 2 if Base is 1
			return (base == 1) and 2 or 0
		end
	end

	for _, item in ipairs(items) do
		local level = get_embedding_level(item.resolved, base_level)
		if current_level == nil then
			current_level = level
		end

		if level ~= current_level then
			table.insert(runs, { text = table.concat(current_run_chars), level = current_level })
			current_run_chars = {}
			current_level = level
		end
		table.insert(current_run_chars, item.char)
	end
	if #current_run_chars > 0 then
		table.insert(runs, { text = table.concat(current_run_chars), level = current_level })
	end

	-- 5. Reorder Runs (L2)
	runs = reorder_runs(runs)

	-- 6. Process Final Output (Reverse characters within runs if needed)
	local result = {}
	local view_is_rtl = (view_direction == M.Dir.RTL)

	for _, run in ipairs(runs) do
		-- Determine if this run should be visually reversed
		-- Run is RTL if level is odd
		local run_is_rtl = (run.level % 2 == 1)
		
		-- Reverse if:
		-- 1. Run is LTR (even) AND View is RTL (Right-Left Mode) -> Neovim flips back to LTR
		-- 2. Run is RTL (odd) AND View is LTR (Normal Mode) -> We flip to see RTL
		-- Combined XOR logic:
		local should_reverse = (run_is_rtl ~= view_is_rtl)

		if should_reverse then
			-- Reverse characters (UTF-8 aware)
			local chars = {}
			for char in string.gmatch(run.text, "[%z\1-\127\194-\244][\128-\191]*") do
				table.insert(chars, char)
			end
			reverse_slice(chars, 1, #chars)
			table.insert(result, table.concat(chars))
		else
			table.insert(result, run.text)
		end
	end

	return table.concat(result)
end

return M