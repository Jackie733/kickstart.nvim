local M = {}

M.bigfile_size = 1.5 * 1024 * 1024

function M.is_bigfile(bufnr)
  bufnr = bufnr or 0
  if vim.b[bufnr].tsien_bigfile or vim.bo[bufnr].filetype == 'bigfile' then
    return true
  end
  local lines = vim.api.nvim_buf_line_count(bufnr)
  return vim.api.nvim_buf_get_offset(bufnr, lines) > M.bigfile_size
end

function M.disable_bigfile(bufnr)
  vim.b[bufnr].tsien_bigfile = true
  vim.b[bufnr].completion = false
  vim.b[bufnr].snacks_indent = false
  vim.b[bufnr].snacks_scope = false
  vim.b[bufnr].snacks_words = false
  vim.b[bufnr].minipairs_disable = true
  vim.b[bufnr].minianimate_disable = true
  vim.b[bufnr].minihipatterns_disable = true
  vim.bo[bufnr].syntax = ''
  vim.treesitter.stop(bufnr)
  vim.wo.foldmethod = 'manual'
  vim.wo.conceallevel = 0
  vim.wo.spell = false
  vim.wo.wrap = false
end

return M
