local project = require 'core.project'

local function frontend_formatters(bufnr)
  if project.has_oxc_tooling(bufnr) then
    local conform = require 'conform'
    local formatters = {}

    if project.has_oxlint(bufnr) and conform.get_formatter_info('oxlint', bufnr).available then
      table.insert(formatters, 'oxlint')
    end
    if project.has_oxfmt(bufnr) and conform.get_formatter_info('oxfmt', bufnr).available then
      table.insert(formatters, 'oxfmt')
    end

    if #formatters > 0 then
      return formatters
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
    notify_on_error = false,
    format_on_save = {
      timeout_ms = 1000,
      lsp_format = 'fallback',
    },
    formatters_by_ft = {
      lua = { 'stylua' },
      python = { 'ruff_organize_imports', 'ruff_fix', 'ruff_format' },
      rust = { 'rustfmt' },
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
