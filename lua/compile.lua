local buf
local current_job

local window = require 'window'

local function buffer()
  if buf and vim.api.nvim_buf_is_valid(buf) then
    return buf
  end

  -- open a scratch window
  buf = vim.api.nvim_create_buf(false, true)
  vim.bo[buf].buftype = 'nofile'
  vim.bo[buf].bufhidden = 'hide'
  vim.bo[buf].swapfile = false
  vim.bo[buf].modified = false
  vim.bo[buf].modifiable = true

  return buf
end

local function append(lines)
  if not lines or #lines == 0 then
    return
  end

  -- jobstart often sends a final {""}; drop it
  if #lines == 1 and lines[1] == '' then
    return
  end

  -- Buffer edits must be scheduled (callbacks can be off the main loop)
  vim.schedule(function()
    local target = buffer()

    local last = vim.api.nvim_buf_line_count(target)

    -- Append at end
    vim.api.nvim_buf_set_lines(target, last, last, false, lines)

    -- keep cursor at end
    local wins = vim.fn.win_findbuf(target)
    for _, win in ipairs(wins) do
      vim.api.nvim_win_set_cursor(win, { vim.api.nvim_buf_line_count(target), 0 })
    end
  end)
end

local function execute(cmd, dir)
  if current_job then
    vim.fn.jobstop(current_job)
  end

  vim.api.nvim_buf_set_lines(buffer(), 0, -1, false, {})

  window.set_buffer_in_right(buffer())

  local job_id = vim.fn.jobstart(vim.fn.has 'win32' == 1 and { 'powershell', '-NoProfile', '-Command', cmd } or { 'sh', '-c', cmd }, {
    cwd = dir,

    -- IMPORTANT: stream, don't wait
    stdout_buffered = false,
    stderr_buffered = false,

    on_stdout = function(_, data, _)
      append(data)
    end,
    on_stderr = function(_, data, _)
      append(data)
    end,
    on_exit = function(_, code, _)
      current_job = nil
      append { '', ('[Process exited with code ' .. code .. ']') }
    end,
  })

  if job_id <= 0 then
    append { '[failed to start job]' }
  else
    current_job = job_id
  end
end

local function find_build_file()
  local cwd = vim.uv.cwd()
  local dir = vim.fs.dirname(vim.api.nvim_buf_get_name(0)) or cwd

  while true do
    if vim.uv.fs_stat(dir .. '/Makefile') ~= nil then
      return 'make clean all', dir
    elseif vim.uv.fs_stat(dir .. '/build.bat') ~= nil then
      return './build.bat', dir
    elseif dir == cwd then
      return nil, nil
    else
      local parent = vim.fs.dirname(dir)
      if not parent or parent == dir then
        return nil, nil
      end

      dir = parent
    end
  end
end

vim.keymap.set('n', '<leader>m', function()
  local command, dir = find_build_file()

  if not command or not dir then
    vim.notify 'No build file found'
    return
  end

  execute(command, dir)
end, { desc = 'Build' })

vim.keymap.set('n', '<leader>km', function()
  if current_job then
    vim.fn.jobstop(current_job)
    current_job = nil
  end
end, { desc = 'Kill current build' })
