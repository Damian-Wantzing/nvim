local M = {}

-- the right window if there is one
local right = nil

-- array of buffer handles
local stack = {}

local function new_right_window(buf)
  right = vim.api.nvim_open_win(buf, true, {
    split = 'right',
  })
  return right
end

local function right_window(buf)
  if right and vim.api.nvim_win_is_valid(right) then
    return right
  end

  local windows = vim.api.nvim_tabpage_list_wins(0)

  if #windows == 1 then
    return new_right_window(buf)
  end

  local config = vim.api.nvim_win_get_config(windows[2])
  if config.relative ~= '' then
    return new_right_window(buf)
  end

  right = windows[2]
  return right
end

local function index_of(table, value)
  for index, current in ipairs(table) do
    if value == current then
      return index
    end
  end
  return nil
end

M.set_buffer_in_right = function(buf)
  local window = right_window(buf)
  local current = vim.api.nvim_win_get_buf(window)

  if current then
    stack[#stack + 1] = current
  end

  local stack_index = index_of(stack, buf)

  if stack_index ~= nil then
    table.remove(stack, stack_index)
  end

  vim.api.nvim_win_set_buf(window, buf)
end

M.activate_right = function()
  vim.api.nvim_set_current_win(right_window())
end

vim.api.nvim_create_autocmd('WinClosed', {
  callback = function(args)
    local closed = tonumber(args.match)
    if right and closed == right then
      local next = stack[#stack]
      if next then
        new_right_window(next)
        table.remove(stack, #stack)
      end
    end
  end,
})

return M
