return {
  {
    'mfussenegger/nvim-lint',
    ft = { 'markdown', 'markdown.mdx' },
    config = function()
      local lint = require 'lint'
      lint.linters_by_ft = {
        markdown = { 'markdownlint' },
        ['markdown.mdx'] = { 'markdownlint' },
      }

      vim.api.nvim_create_autocmd('BufWritePost', {
        group = vim.api.nvim_create_augroup('lint', { clear = true }),
        callback = function(event)
          if vim.bo[event.buf].modifiable and lint.linters_by_ft[vim.bo[event.buf].filetype] then
            vim.api.nvim_buf_call(event.buf, lint.try_lint)
          end
        end,
      })
    end,
  },
}
