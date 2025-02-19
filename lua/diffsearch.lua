local telescope = require 'telescope.builtin'
local finders = require 'telescope.finders'

local function git_diff()
  -- local output = vim.fn.systemlist 'git rev-parse --is-inside-work-tree 2>/dev/null'
  local output = vim.fn.systemlist 'git diff --name-only 2>/dev/null'

  if vim.v.shell_error ~= 0 then
    return {}
  end

  local files = {}
  for _, line in ipairs(output) do
    table.insert(files, line)
  end

  return files
end

local function svn_diff()
  local output = vim.fn.systemlist 'svn status 2>/dev/null'

  if vim.v.shell_error ~= 0 then
    return {}
  end

  local files = {}
  for _, line in ipairs(output) do
    local status, file = line:match '([AMD?])%s+(%S+)'
    if status and file then
      table.insert(files, file)
    end
  end

  return files
end

local function diff_files()
  local files = {}

  for _, file in ipairs(git_diff()) do
    table.insert(files, file)
  end
  for _, file in ipairs(svn_diff()) do
    table.insert(files, file)
  end

  return files
end

local function pick_diff_files()
  telescope.find_files {
    prompt_title = 'Diff Files',
    cwd = vim.fn.getcwd(),
    finder = finders.new_table {
      results = diff_files(),
    },
  }
end

return {
  pick_diff_files = pick_diff_files,
}
