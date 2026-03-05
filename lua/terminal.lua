local buf = nil

local window = require 'window'

vim.keymap.set('n', '<leader>tt', function()
  if buf and vim.api.nvim_buf_is_valid(buf) then
    window.set_buffer_in_right(buf)
    window.activate_right()
    vim.cmd 'startinsert'
  else
    buf = vim.api.nvim_create_buf(false, true)
    window.set_buffer_in_right(buf)
    window.activate_right()
    vim.fn.termopen(vim.o.shell)
    vim.cmd 'startinsert'
  end
end, { desc = 'Open terminal' })
