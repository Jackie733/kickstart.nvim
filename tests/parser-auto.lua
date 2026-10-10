-- Use a private parser directory; never remove or replace the user's parsers.
local function run()
  local ts = require 'nvim-treesitter'
  local private = assert(vim.env.TSIEN_TEST_DIR, 'Set TSIEN_TEST_DIR to a private test directory')
  vim.opt.runtimepath:remove(vim.fn.stdpath 'data' .. '/site')
  ts.setup { install_dir = private }
  assert(#vim.api.nvim_get_runtime_file('parser/rust.*', true) == 0, 'Test parser directory must start empty')
  local real_install = ts.install
  local installs = 0
  ts.install = function(languages, options)
    installs = installs + 1
    return real_install(languages, options)
  end
  local function buffer()
    local b = vim.api.nvim_create_buf(true, false)
    vim.api.nvim_set_current_buf(b)
    vim.api.nvim_buf_set_lines(b, 0, -1, false, { 'fn main() { let count = 1; }' })
    vim.bo[b].filetype = 'rust'
    return b
  end
  local live, removed, changed = buffer(), buffer(), buffer()
  -- Let all three scheduled FileType handlers enter the shared installation.
  vim.wait(50, function()
    return false
  end)
  vim.api.nvim_buf_delete(removed, { force = true })
  vim.bo[changed].filetype = 'text'
  assert(
    vim.wait(90000, function()
      return vim.treesitter.highlighter.active[live] ~= nil
    end, 100),
    'Missing Rust parser was not installed and activated'
  )
  assert(installs == 1, 'The same parser was compiled more than once')
  assert(not vim.treesitter.highlighter.active[changed], 'Changed filetype received stale Rust highlighting')
  assert(vim.bo[live].indentexpr ~= '', 'New parser did not restore indentation')
  assert(not vim.treesitter.get_parser(live, 'rust'):parse()[1]:root():has_error())
  print 'PARSER_AUTO_TESTS_OK: installed once, activated without restart, deleted/changed buffers skipped'
end
vim.defer_fn(function()
  local ok, err = xpcall(run, debug.traceback)
  if not ok then
    print(err)
    vim.cmd 'cquit 1'
  else
    vim.cmd 'qa!'
  end
end, 100)
