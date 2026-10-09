local project = require 'core.project'
local save_timeout_ms = { lua = 300, markdown = 750, sql = 750 }

local function frontend_formatters(bufnr)
  if project.has_oxfmt(bufnr) then
    local conform = require 'conform'
    if conform.get_formatter_info('oxfmt', bufnr).available then
      return { 'oxfmt' }
    end
  end

  return { 'prettierd', 'prettier', stop_after_first = true }
end

return {
  'stevearc/conform.nvim',
  event = { 'BufWritePre' },
  cmd = { 'ConformInfo' },
  init = function()
    vim.o.formatexpr = "v:lua.require'conform'.formatexpr()"
  end,
  keys = {
    {
      '<leader>f',
      function()
        require('conform').format { async = true, lsp_format = 'fallback' }
      end,
      mode = '',
      desc = '[F]ormat buffer',
    },
  },
  opts = {
    notify_on_error = true,
    format_on_save = function(bufnr)
      if require('core.buffer').is_bigfile(bufnr) then
        return
      end
      return { timeout_ms = save_timeout_ms[vim.bo[bufnr].filetype] or 500, lsp_format = 'fallback' }
    end,
    formatters_by_ft = {
      lua = { 'stylua' },
      python = { 'ruff_organize_imports', 'ruff_format' },
      rust = { 'rustfmt' },
      sql = { 'sqruff' },
      sh = { 'shfmt' },
      bash = { 'shfmt' },
      javascript = frontend_formatters,
      typescript = frontend_formatters,
      javascriptreact = frontend_formatters,
      typescriptreact = frontend_formatters,
      vue = frontend_formatters,
      json = { 'prettierd', 'prettier', stop_after_first = true },
      jsonc = { 'prettierd', 'prettier', stop_after_first = true },
      css = { 'prettierd', 'prettier', stop_after_first = true },
      scss = { 'prettierd', 'prettier', stop_after_first = true },
      html = { 'prettierd', 'prettier', stop_after_first = true },
      markdown = { 'prettierd', 'prettier', stop_after_first = true },
      ['markdown.mdx'] = { 'prettierd', 'prettier', stop_after_first = true },
      yaml = { 'prettierd', 'prettier', stop_after_first = true },
      yml = { 'prettierd', 'prettier', stop_after_first = true },
    },
  },
}
