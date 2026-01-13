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
      -- Base direction is 'R'.
      -- Latin chunks (L) will be reversed by process_line so they appear correctly LTR after vim flips them.
      -- Hebrew chunks (R) will be kept as-is, so they appear correctly RTL after vim flips them.
      processed = logic.process_line(line, 'R')
    else
      -- Mode: Left-to-Right (Neovim normal)
      -- Base direction is 'L'.
      -- Hebrew chunks (R) will be reversed by process_line to appear RTL.
      -- Latin chunks (L) will be kept as-is.
      processed = logic.process_line(line, 'L')
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
