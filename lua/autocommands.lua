-- Highlight when yanking (copying) text
vim.api.nvim_create_autocmd('TextYankPost', {
  desc = 'Highlight when yanking (copying) text',
  group = vim.api.nvim_create_augroup('kickstart-highlight-yank', { clear = true }),
  callback = function()
    vim.highlight.on_yank()
  end,
})

-- Only append a comment line in docblocks
-- vim.api.nvim_create_autocmd('TextChangedI', {
--   group = vim.api.nvim_create_augroup('DocBlockAdjust', { clear = true }),
--   pattern = '*',
--   callback = function()
--     local current = vim.api.nvim_win_get_cursor(vim.api.nvim_get_current_win())[1]
--     local previous = vim.api.nvim_buf_get_lines(vim.api.nvim_get_current_buf(), current - 2, current - 1, false)[1]
--
--     print(previous)
--     -- Check if the line starts with a docblock pattern (/**) or just *
--     if string.match(previous, '^%s*/%*%*') or string.match(previous, '^%s*%*') then
--       -- Set formatoptions to continue comments
--       vim.cmd [[set fo=c fo=r fo=o]]
--     else
--       -- Do not continue comments for regular lines
--       vim.cmd [[set fo-=c fo-=r fo-=o]]
--     end
--   end,
-- })
