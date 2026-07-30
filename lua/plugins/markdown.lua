return {
  {
    'MeanderingProgrammer/render-markdown.nvim',
    ft = { 'markdown', 'markdown.mdx' },
    dependencies = {
      'nvim-treesitter/nvim-treesitter',
      'echasnovski/mini.icons',
    },
    keys = {
      { '<leader>um', '<cmd>RenderMarkdown toggle<cr>', desc = 'Toggle [M]arkdown Preview' },
      { '<leader>uM', '<cmd>RenderMarkdown preview<cr>', desc = 'Open [M]arkdown Split Preview' },
    },
    init = function()
      local markdown_augroup = vim.api.nvim_create_augroup('markdown-local-options', { clear = true })
      vim.api.nvim_create_autocmd('FileType', {
        group = markdown_augroup,
        pattern = { 'markdown', 'markdown.mdx' },
        callback = function()
          vim.opt_local.wrap = true
          vim.opt_local.linebreak = true
          vim.opt_local.spell = true
        end,
      })
    end,
    opts = {
      file_types = { 'markdown', 'markdown.mdx' },
    },
  },
}
