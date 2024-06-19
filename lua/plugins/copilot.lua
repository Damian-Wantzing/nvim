return {
  'github/copilot.vim',
  config = function()
    -- set keymap for disabling and enabling copilot
    vim.keymap.set('n', '<leader>ce', '<cmd>Copilot enable<CR>')
    vim.keymap.set('n', '<leader>cd', '<cmd>Copilot disable<CR>')

    -- set keymap for checking status of copilot
    vim.keymap.set('n', '<leader>cs', '<cmd>Copilot status<CR>')
  end,
}
