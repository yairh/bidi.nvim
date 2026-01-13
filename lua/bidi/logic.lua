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

	-- 3. Resolve Neutrals
	-- Neutrals take the direction of surrounding strong types.
	-- If surrounded by same type -> become that type.
	-- If mixed or boundary -> default to para_direction (Base Direction).
	for i, item in ipairs(items) do
		if item.type == M.Dir.NEUTRAL then
			local prev_strong = para_direction
			-- Look backward for strong type
			for j = i - 1, 1, -1 do
				if items[j].type ~= M.Dir.NEUTRAL then
					prev_strong = items[j].type
					break
				end
			end

			local next_strong = para_direction
			-- Look forward for strong type
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

	-- 4. Group chunks and process
	-- If chunk type differs from view_direction, it needs to be reversed visually.
	local result = {}
	local current_chunk = {}
	local current_type = nil

	local function flush()
		if #current_chunk == 0 then return end
		local text = table.concat(current_chunk)

		if current_type ~= view_direction then
			-- Reverse the text chunk (UTF-8 aware)
			local chars = {}
			for char in string.gmatch(text, "[%z\1-\127\194-\244][\128-\191]*") do
				table.insert(chars, char)
			end
			for i = 1, math.floor(#chars / 2) do
				chars[i], chars[#chars - i + 1] = chars[#chars - i + 1], chars[i]
			end
			table.insert(result, table.concat(chars))
		else
			table.insert(result, text)
		end
		current_chunk = {}
	end

	for _, item in ipairs(items) do
		if current_type == nil then
			current_type = item.resolved
		elseif current_type ~= item.resolved then
			flush()
			current_type = item.resolved
		end
		table.insert(current_chunk, item.char)
	end
	flush()

	return table.concat(result)
end

return M
