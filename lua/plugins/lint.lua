return {

  { -- Linting
    'mfussenegger/nvim-lint',
    event = { 'BufReadPre', 'BufNewFile' },
    config = function()
      local lint = require 'lint'
      -- NOTE: eslint 已通过 LSP 提供，无需在此重复配置
      -- 只保留 LSP 不覆盖的 linter
      lint.linters_by_ft = {
        markdown = { 'markdownlint' },
        python = { 'ruff' },
      }

      -- Create autocommand which carries out the actual linting
      -- on the specified events.
      -- NOTE: 移除了 BufEnter 以减少打开文件时的延迟
      local lint_augroup = vim.api.nvim_create_augroup('lint', { clear = true })
      vim.api.nvim_create_autocmd({ 'BufWritePost', 'InsertLeave' }, {
        group = lint_augroup,
        callback = function()
          -- Only run the linter in buffers that you can modify in order to
          -- avoid superfluous noise, notably within the handy LSP pop-ups that
          -- describe the hovered symbol using Markdown.
          if vim.bo.modifiable then
            -- 添加延迟，避免阻塞 UI
            vim.defer_fn(function()
              lint.try_lint()
            end, 100)
          end
        end,
      })
    end,
  },
}
