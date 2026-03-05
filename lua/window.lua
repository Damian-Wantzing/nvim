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

  if #windows == 2 then
    local left_buf = vim.api.nvim_win_get_buf(windows[1])
    if left_buf and vim.bo[left_buf].filetype == 'neo-tree' then
      return new_right_window(buf)
    end
  end

  local right_win = windows[1]
  local right_col = vim.api.nvim_win_get_position(right_win)[2]

  for _, win in ipairs(windows) do
    local col = vim.api.nvim_win_get_position(win)[2]
    if col > right_col and vim.api.nvim_win_get_config(win).relative == '' then
      right_col = col
      right_win = win
    end
  end

  if right_win == windows[1] then
    return new_right_window(buf)
  end

  right = right_win
  return right_win
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
