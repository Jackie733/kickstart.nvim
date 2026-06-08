return {
  'folke/trouble.nvim',
  cmd = 'Trouble',
  opts = {
    win = {
      type = 'split',
      position = 'bottom',
      size = 15,
    },
  },
  keys = {
    { '<leader>xx', '<cmd>Trouble diagnostics toggle<cr>', desc = 'Diagnostics' },
    { '<leader>xX', '<cmd>Trouble diagnostics toggle filter.buf=0<cr>', desc = 'Buffer Diagnostics' },
    { '<leader>xl', '<cmd>Trouble loclist toggle<cr>', desc = 'Location List' },
    { '<leader>xq', '<cmd>Trouble qflist toggle<cr>', desc = 'Quickfix List' },
    { '<leader>xr', '<cmd>Trouble lsp toggle focus=false win.position=right<cr>', desc = 'LSP References' },
    { '<leader>xs', '<cmd>Trouble symbols toggle focus=false<cr>', desc = 'Symbols' },
  },
}
