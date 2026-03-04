return {
  {
    'GCBallesteros/jupytext.nvim',
    lazy = false,
    opts = {
      style = 'markdown',
      output_extension = 'md',
      force_ft = 'markdown',
    },
    config = function(_, opts)
      if vim.fn.executable 'jupytext' == 1 then
        require('jupytext').setup(opts)
        return
      end

      local group = vim.api.nvim_create_augroup('jupytext-missing-warning', { clear = true })
      vim.api.nvim_create_autocmd('BufReadPre', {
        group = group,
        pattern = '*.ipynb',
        callback = function()
          vim.schedule(function()
            vim.notify('jupytext CLI not found. Install with: pip install jupytext', vim.log.levels.ERROR)
          end)
        end,
      })
    end,
  },
  {
    'benlubas/molten-nvim',
    version = '^1.0.0',
    build = ':UpdateRemotePlugins',
    cmd = {
      'MoltenInit',
      'MoltenEvaluateLine',
      'MoltenEvaluateVisual',
      'MoltenEvaluateOperator',
      'MoltenReevaluateCell',
      'MoltenEnterOutput',
      'MoltenHideOutput',
      'MoltenImportOutput',
      'MoltenExportOutput',
    },
    keys = {
      { '<leader>ji', '<cmd>MoltenInit<cr>', desc = 'Jupyter Init Kernel' },
      { '<leader>je', '<cmd>MoltenEvaluateOperator<cr>', desc = 'Jupyter Evaluate Operator' },
      { '<leader>jl', '<cmd>MoltenEvaluateLine<cr>', desc = 'Jupyter Evaluate Line' },
      { '<leader>jr', '<cmd>MoltenReevaluateCell<cr>', desc = 'Jupyter Re-evaluate Cell' },
      { '<leader>jo', '<cmd>noautocmd MoltenEnterOutput<cr>', desc = 'Jupyter Open Output' },
      { '<leader>jh', '<cmd>MoltenHideOutput<cr>', desc = 'Jupyter Hide Output' },
      { '<leader>jv', ':<C-u>MoltenEvaluateVisual<cr>gv', mode = 'v', desc = 'Jupyter Evaluate Visual' },
    },
    init = function()
      vim.g.molten_image_provider = 'none'
      vim.g.molten_auto_open_output = false
      vim.g.molten_wrap_output = true
      vim.g.molten_virt_text_output = true
      vim.g.molten_virt_lines_off_by_1 = true
    end,
  },
}
