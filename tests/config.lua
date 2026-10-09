local function check(condition, message)
  assert(condition, message)
end

local function loaded(name)
  return require('lazy.core.config').plugins[name]._.loaded ~= nil
end

local function buffer(filetype, lines)
  local bufnr = vim.api.nvim_create_buf(true, false)
  vim.api.nvim_set_current_buf(bufnr)
  vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, lines)
  vim.bo[bufnr].filetype = filetype
  return bufnr
end

local function selection_width()
  local start = vim.fn.getpos 'v'
  local cursor = vim.api.nvim_win_get_cursor(0)
  check(start[2] == cursor[1], 'Selection should remain on the fixture line')
  return math.abs(start[3] - cursor[2] - 1) + 1
end

local function press(key)
  vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes(key, true, false, true), 'xt', false)
end

local function run()
  -- Headless startup does not emit UIEnter/VeryLazy; exercise that phase explicitly.
  vim.api.nvim_exec_autocmds('User', { pattern = 'VeryLazy' })
  for _, name in ipairs { 'telescope.nvim', 'blink.cmp', 'LuaSnip', 'nvim-dap', 'nvim-dap-python', 'venv-selector.nvim' } do
    check(not loaded(name), name .. ' loaded before its first action')
  end
  check(vim.g.rustaceanvim.dap.autoload_configurations == false, 'Rust DAP autoload is enabled')
  check(vim.g.rustaceanvim.server.default_settings['rust-analyzer'].check.command == 'check', 'Rust must use routine cargo check')
  check(vim.fn.exists ':TSInstallConfigured' == 2, 'Configured parser installation command is missing')
  check(vim.fn.exists ':MasonToolsInstall' == 2, 'Tool installation command is not available from an empty start')
  vim.api.nvim_exec_autocmds('BufReadPre', { buffer = vim.api.nvim_get_current_buf() })

  local fixtures = {
    { 'typescript', { 'const total: number = 1 + 2;' } },
    { 'rust', { 'fn main() { let total = 1 + 2; }' } },
    { 'python', { 'def total():', '    return 1 + 2' } },
    { 'lua', { 'local total = 1 + 2' } },
  }
  for _, fixture in ipairs(fixtures) do
    local bufnr = buffer(fixture[1], fixture[2])
    check(
      vim.wait(1000, function()
        return vim.treesitter.highlighter.active[bufnr] ~= nil
      end),
      fixture[1] .. ' subsequent buffer has no Treesitter highlight'
    )
  end

  vim.api.nvim_win_set_cursor(0, { 1, 14 })
  press '<C-Space>'
  check(vim.fn.mode() == 'v', 'Syntax node selection did not enter Visual mode')
  local first = selection_width()
  press '<C-Space>'
  local expanded = selection_width()
  check(expanded > first, 'Syntax node selection did not expand')
  press '<BS>'
  check(selection_width() < expanded, 'Syntax node selection did not shrink')
  press '<Esc>'

  local changed = buffer('python', { 'value = 1' })
  check(
    vim.wait(1000, function()
      return vim.treesitter.highlighter.active[changed] ~= nil
    end),
    'Python fixture did not highlight'
  )
  vim.bo[changed].filetype = 'typescript'
  check(
    vim.wait(1000, function()
      local highlighter = vim.treesitter.highlighter.active[changed]
      return highlighter and highlighter.tree:lang() == 'typescript'
    end),
    'Filetype change retained the previous parser'
  )

  local format = require('plugins.conform').opts.format_on_save
  local lua_buf = buffer('lua', { 'local total = 1 + 2' })
  check(format(lua_buf).timeout_ms == 300, 'Lua save budget is wrong')
  local rust_buf = buffer('rust', { 'fn main() {}' })
  check(format(rust_buf).timeout_ms == 500, 'Rust save budget is wrong')
  local big = buffer('bigfile', { 'plain text' })
  check(vim.b[big].completion == false and vim.b[big].snacks_scope == false, 'Big file helpers remain enabled')
  check(vim.bo[big].syntax == '' and not vim.treesitter.highlighter.active[big], 'Big file still has syntax highlighting')
  check(format(big) == nil, 'Big file save formatting is enabled')
  -- Unsaved growth also skips formatting before filetype is reclassified.
  local growing = buffer('text', { string.rep('x', require('core.buffer').bigfile_size + 1) })
  check(format(growing) == nil, 'Oversized normal buffer still formats on save')

  local fallback = buffer('tsien_missing_parser', { 'plain text' })
  vim.bo[fallback].syntax = 'sh'
  local removed = buffer('rust', { 'fn main() {}' })
  vim.api.nvim_buf_delete(removed, { force = true })
  vim.api.nvim_set_current_buf(fallback)
  vim.wait(100, function()
    return false
  end)
  check(not vim.treesitter.highlighter.active[fallback] and vim.bo[fallback].syntax == 'sh', 'Missing parser lost native syntax fallback')

  require('lazy').load { plugins = { 'telescope.nvim' } }
  check(type(require('telescope').extensions.bookmarks.list) == 'function', 'Bookmarks picker did not load on demand')
  vim.api.nvim_exec_autocmds('InsertEnter', {})
  check(loaded 'blink.cmp' and loaded 'LuaSnip', 'Completion did not load on InsertEnter')
  require('lazy').load { plugins = { 'nvim-dap' } }
  check(type(require('dap').adapters['pwa-node']) == 'table', 'DAP adapters did not configure on demand')
  io.stdout:write 'CONFIG_TESTS_OK\n'
end

vim.defer_fn(function()
  local ok, err = xpcall(run, debug.traceback)
  if not ok then
    io.stderr:write(err .. '\n')
    vim.cmd 'cquit 1'
  else
    vim.cmd 'qa!'
  end
end, 100)
