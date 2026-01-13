local M = {}

function M.process_line(line, should_reverse_chunk)
  local result = {}
  local current_segment = {}
  -- We track the 'type' of the current segment based on the predicate
  local current_should_reverse = nil 

  local function flush()
    if #current_segment > 0 then
      local text = table.concat(current_segment)
      if current_should_reverse then
        -- Reverse the text (UTF-8 aware)
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
      current_segment = {}
    end
  end

  for char in string.gmatch(line, "[%z\1-\127\194-\244][\128-\191]*") do
    local should_reverse = should_reverse_chunk(char)

    if current_should_reverse == nil then
      current_should_reverse = should_reverse
    elseif current_should_reverse ~= should_reverse then
      flush()
      current_should_reverse = should_reverse
    end
    table.insert(current_segment, char)
  end
  flush()

  return table.concat(result)
end

function M.is_hebrew(char)
  local codepoint = vim.fn.char2nr(char)
  return (codepoint >= 0x0590 and codepoint <= 0x05FF)
end

function M.is_latin(char)
  -- Simple check for ASCII or Latin-1 Supplement or Latin Extended
  -- We'll assume anything NOT Hebrew is "Latin-ish" for the purpose of rightleft fix?
  -- Or strictly [a-zA-Z]?
  -- Let's stick to strict ASCII range for now to be safe, or 0x0000-0x024F
  local codepoint = vim.fn.char2nr(char)
  return (codepoint <= 0x024F)
end

return M