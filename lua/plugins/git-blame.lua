return {
  {
    'f-person/git-blame.nvim',
    event = 'VeryLazy',
    opts = {
      enabled = true,
      message_template = ' <summary> • <date> • <author> • <<sha>>',
      date_format = '%m-%d-%Y %H:%M:%S',
      virtual_text_column = 1,
    },
    config = function(_, opts)
      require('gitblame').setup(opts)
      
      -- 可选：添加键映射来快速切换显示
      vim.keymap.set('n', '<leader>gb', '<cmd>GitBlameToggle<cr>', { desc = 'Toggle [g]it [b]lame' })
      vim.keymap.set('n', '<leader>gB', '<cmd>GitBlameOpenCommitURL<cr>', { desc = '[G]it [B]lame open commit URL' })
    end,
  },
}