local M = {}
local logic = require("bidi.logic")
local ns = vim.api.nvim_create_namespace("bidi")

---Refresh the bidi rendering for a buffer
---@param bufnr integer|nil Buffer number (defaults to current buffer if nil/0)
function M.refresh_buffer(bufnr)
  if not bufnr or bufnr == 0 then
    bufnr = vim.api.nvim_get_current_buf()
  end
  
  -- Check window option 'rightleft'
  -- Note: Autocmd might fire when buffer is not in current window?
  -- We should iterate windows displaying this buffer or check current window.
  -- For simplicity, check current window if it displays the buffer.
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
      -- Mode: Right-to-Left (Neovim flips everything)
      -- Hebrew: Good.
      -- Latin: Needs to be reversed back.
      processed = logic.process_line(line, function(char)
        return not logic.is_hebrew(char)
      end)
    else
      -- Mode: Left-to-Right (Neovim normal)
      -- Hebrew: Needs to be reversed to look readable.
      -- Latin: Good.
      processed = logic.process_line(line, function(char)
        return logic.is_hebrew(char)
      end)
    end

    if processed ~= line then
      vim.api.nvim_buf_set_extmark(bufnr, ns, i - 1, 0, {
        virt_text = {{ processed }},
        virt_text_pos = "overlay",
        hl_mode = "combine",
      })
    end
  end
end

---Enable the bidi rendering plugin
function M.enable()
  local group = vim.api.nvim_create_augroup("BidiGroup", { clear = true })
  
  vim.api.nvim_create_autocmd({"TextChanged", "TextChangedI", "BufWinEnter", "OptionSet"}, {
    group = group,
    callback = function(args)
      -- If OptionSet, check if it was 'rightleft'
      if args.event == "OptionSet" and args.match ~= "rightleft" then
        return
      end
      M.refresh_buffer(args.buf)
    end
  })
end

return M