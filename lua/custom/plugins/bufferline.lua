return {
  'akinsho/bufferline.nvim',
  version = '*',
  dependencies = 'nvim-tree/nvim-web-devicons',
  keys = {
    { '<leader>bp', '<Cmd>BufferLineTogglePin<CR>', desc = 'Toggle Pin' },
    { '<leader>bP', '<Cmd>BufferLineGroupClose ungrouped<CR>', desc = 'Delete Non-Pinned Buffers' },
    { '<leader>br', '<Cmd>BufferLineCloseRight<CR>', desc = 'Delete Buffers to the Right' },
    { '<leader>bl', '<Cmd>BufferLineCloseLeft<CR>', desc = 'Delete Buffers to the Left' },
    { '<S-h>', '<cmd>BufferLineCyclePrev<cr>', desc = 'Prev Buffer' },
    { '<S-l>', '<cmd>BufferLineCycleNext<cr>', desc = 'Next Buffer' },
    { '[b', '<cmd>BufferLineCyclePrev<cr>', desc = 'Prev Buffer' },
    { ']b', '<cmd>BufferLineCycleNext<cr>', desc = 'Next Buffer' },
    { '[B', '<cmd>BufferLineMovePrev<cr>', desc = 'Move buffer prev' },
    { ']B', '<cmd>BufferLineMoveNext<cr>', desc = 'Move buffer next' },
  },
  -- FIXME: did not show bufferline
  config = function()
    vim.opt.termguicolors = true
    local bufferline = require 'bufferline'
    bufferline.setup {
      options = {
        close_command = nil,
        right_mouse_command = nil,
        separator_style = 'slant',
        hover = {
          enabled = true,
          delay = 200,
          reveal = { 'close' },
        },
        diagnostics = 'nvim_lsp',
        offsets = {
          {
            filetype = 'NvimTree',
            text = 'File Explorer',
            text_align = 'center',
            separator = true,
          },
        },
        always_show_bufferline = true,
      },
    }
  end,
}
