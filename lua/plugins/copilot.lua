local state = require 'copilotstate'

vim.keymap.set('n', '<leader>ce', function()
  state.store(true)
end)
vim.keymap.set('n', '<leader>cd', function()
  state.store(false)
end)

local function reload()
  local on = state.load()

  if on then
    vim.cmd 'Copilot enable'
  else
    vim.cmd 'Copilot disable'
  end
end

state.watch(function()
  reload()
end)

return {
  'github/copilot.vim',
  config = function()
    -- set keymap for checking status of copilot
    vim.keymap.set('n', '<leader>cs', '<cmd>Copilot status<CR>')

    reload()
  end,
}
