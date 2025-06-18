local M = {}

local uv = vim.loop

local state_file = vim.fn.stdpath 'config' .. '/lua/copilot.state'

function M.load()
  local file = io.open(state_file, 'r')

  -- fallback is on
  if not file then
    return true
  end

  local content = file:read 'all'

  file:close()

  return content:match '^1' ~= nil
end

function M.store(state)
  local file = io.open(state_file, 'w')

  if not file then
    return false
  end

  if state then
    file:write '1'
  else
    file:write '0'
  end

  file:close()

  return true
end

local watcher = nil

function M.watch(callback)
  if watcher then
    return
  end

  watcher = uv.new_fs_event()

  if not watcher then
    return false
  end

  watcher:start(state_file, {}, function()
    vim.schedule(callback)
  end)

  return true
end

function M.is_enabled()
  return M.load()
end

return M
