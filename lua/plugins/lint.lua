return {

  { -- Linting
    'mfussenegger/nvim-lint',
    event = { 'BufReadPre', 'BufNewFile' },
    config = function()
      local lint = require 'lint'
      local project = require 'core.project'

      lint.linters.oxlint.cmd = function()
        return project.find_node_bin(0, 'oxlint') or 'oxlint'
      end

      -- NOTE: eslint 已通过 LSP 提供，无需在此重复配置
      -- Ruff 也由 LSP 提供，只保留 LSP 不覆盖的 linter
      lint.linters_by_ft = {
        markdown = { 'markdownlint' },
      }

      local function try_oxlint(bufnr)
        if not project.is_frontend_filetype(vim.bo[bufnr].filetype) or not project.has_oxlint(bufnr) then
          return
        end
        if not project.find_node_bin(bufnr, 'oxlint') then
          return
        end

        vim.api.nvim_buf_call(bufnr, function()
          lint.try_lint('oxlint', { cwd = project.oxlint_root(bufnr) })
        end)
      end

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
            local bufnr = vim.api.nvim_get_current_buf()
            vim.defer_fn(function()
              if not vim.api.nvim_buf_is_valid(bufnr) then
                return
              end

              vim.api.nvim_buf_call(bufnr, function()
                lint.try_lint()
              end)
              try_oxlint(bufnr)
            end, 100)
          end
        end,
      })
    end,
  },
}
