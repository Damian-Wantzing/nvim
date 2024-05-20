return {
  {
    'brett-griffin/phpdocblocks.vim',
    config = function()
      vim.keymap.set('n', '<leader>pd', '<cmd>PHPDocBlocks<CR>', { desc = '[P]HP [D]ocblock' })
    end,
  },
}
