return {
  {
    'MeanderingProgrammer/render-markdown.nvim',
    ft = { 'markdown' },
    cmd = { 'RenderMarkdown' },
    dependencies = {
      'nvim-treesitter/nvim-treesitter',
      'echasnovski/mini.icons',
    },
    keys = {
      { '<leader>um', '<cmd>RenderMarkdown toggle<cr>', desc = 'Toggle [M]arkdown Render' },
    },
    init = function()
      local markdown_augroup = vim.api.nvim_create_augroup('markdown-local-options', { clear = true })
      vim.api.nvim_create_autocmd('FileType', {
        group = markdown_augroup,
        pattern = 'markdown',
        callback = function()
          vim.opt_local.wrap = true
          vim.opt_local.linebreak = true
          vim.opt_local.spell = true
          vim.opt_local.conceallevel = 2
        end,
      })
    end,
    opts = {},
  },
}
