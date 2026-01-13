local M = {}

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

---Process a line of text, reordering bidirectional segments for visual display
---@param line string The input line of text
---@param base_direction "L"|"R" The base paragraph direction ('L' for LTR, 'R' for RTL)
---@return string The processed line
function M.process_line(line, base_direction)
  local items = {}
  
  -- 1. Parse and classify characters
  for char in string.gmatch(line, "[%z\1-\127\194-\244][\128-\191]*") do
    local type = 'L' -- Default to Strong LTR (includes Numbers, Latin, non-Hebrew Unicode)
    
    if M.is_hebrew(char) then
      type = 'R'
    elseif M.is_neutral(char) then
      type = 'N'
    end
    
    table.insert(items, {char = char, type = type})
  end

  -- 2. Resolve Neutrals
  -- Neutrals take the direction of surrounding strong types.
  -- If surrounded by same type (R-N-R or L-N-L) -> become that type.
  -- If mixed (R-N-L) or boundary -> default to base_direction.
  for i, item in ipairs(items) do
    if item.type == 'N' then
      local prev_strong = base_direction
      -- Look backward for strong type
      for j = i - 1, 1, -1 do
        if items[j].type ~= 'N' then
          prev_strong = items[j].type
          break
        end
      end
      
      local next_strong = base_direction
      -- Look forward for strong type
      for j = i + 1, #items do
        if items[j].type ~= 'N' then
          next_strong = items[j].type
          break
        end
      end
      
      if prev_strong == next_strong then
        item.resolved = prev_strong
      else
        item.resolved = base_direction
      end
    else
      item.resolved = item.type
    end
  end

  -- 3. Group chunks and process
  -- If chunk type differs from base_direction, it needs to be reversed visually.
  local result = {}
  local current_chunk = {}
  local current_type = nil 

  local function flush()
    if #current_chunk == 0 then return end
    local text = table.concat(current_chunk)
    
    if current_type ~= base_direction then
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