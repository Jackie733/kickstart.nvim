local function run()
  -- Optional pinned upstream reference; routine checks require no plugin.
  local reference = vim.env.TSIEN_THEME_REFERENCE
  if reference then
    assert(vim.fn.isdirectory(reference) == 1, 'Reference theme directory is missing')
    vim.opt.rtp:append(reference)
    local baseline = '35cb97959ef01f7193c94c404c13ddb3d4346654'
    local revision = vim.trim(vim.fn.system { 'git', '-C', reference, 'rev-parse', 'HEAD' })
    assert(revision == baseline, 'Reference revision differs from the documented baseline: ' .. revision)
    require('gruber-darker').setup {}
  end

  local function snapshot()
    local terminal = {}
    for index = 0, 15 do
      terminal[index + 1] = vim.g['terminal_color_' .. index]
    end
    terminal.background = vim.g.terminal_color_background
    terminal.foreground = vim.g.terminal_color_foreground
    local definitions = vim.api.nvim_get_hl(0, {})
    local resolved = {}
    for name in pairs(definitions) do
      resolved[name] = vim.api.nvim_get_hl(0, { name = name, link = false })
    end
    return {
      definitions = definitions,
      resolved = resolved,
      terminal = terminal,
      cursor = vim.o.guicursor,
      background = vim.o.background,
    }
  end

  -- Seed a semantic group to ensure the upstream clearing behavior is exercised.
  vim.api.nvim_set_hl(0, '@lsp.type.function', { fg = '#ff0000' })
  vim.cmd.colorscheme 'default'
  vim.cmd.colorscheme(reference and 'gruber-darker' or 'tsien-dark')
  local expected = snapshot()
  vim.cmd.colorscheme 'default'
  vim.cmd.colorscheme 'tsien-dark'
  assert(vim.g.colors_name == 'tsien-dark', 'Local theme did not load')
  local actual = snapshot()
  assert(vim.api.nvim_get_hl(0, { name = '@lsp.type.function' }).fg == nil, 'Semantic styling was not cleared')
  for name, attrs in pairs(expected.definitions) do
    assert(vim.deep_equal(attrs, actual.definitions[name]), 'Definition differs: ' .. name)
    assert(vim.deep_equal(expected.resolved[name], actual.resolved[name]), 'Resolved appearance differs: ' .. name)
  end
  for name, attrs in pairs(actual.definitions) do
    assert(vim.deep_equal(attrs, expected.definitions[name]), 'Extra or different definition: ' .. name)
  end
  assert(vim.deep_equal(actual.terminal, expected.terminal), 'Terminal palette differs')
  assert(actual.cursor == expected.cursor, 'Cursor styling differs')
  assert(actual.background == expected.background, 'Background mode differs')

  for _, filetype in ipairs { 'help', 'qf' } do
    vim.api.nvim_exec_autocmds('FileType', { group = 'TsienDark', pattern = filetype })
    assert(vim.wo.winhighlight == 'Normal:NormalSB,SignColumn:SignColumnSB', 'Sidebar behavior differs')
  end
  require('theme.palette').bg = '#ffffff'
  package.loaded['theme.highlights'] = function()
    error 'Stale highlights module was reused'
  end
  vim.cmd.colorscheme 'tsien-dark'
  assert(vim.deep_equal(snapshot(), actual), 'Reload did not restore source definitions')
  vim.cmd.colorscheme 'default'
  assert(vim.fn.exists '#TsienDark' == 0, 'Local autocmds leaked after switching away')
  vim.cmd.colorscheme 'tsien-dark'
  assert(vim.deep_equal(snapshot(), actual), 'Switching back changed appearance')
  assert(#vim.api.nvim_get_autocmds { group = 'TsienDark' } == 4, 'Local autocmds duplicated')
  print(
    (reference and 'THEME_BASELINE_OK: ' or 'THEME_TESTS_OK: ')
      .. vim.tbl_count(expected.definitions)
      .. ' highlight groups, terminal palette, cursor, sidebar, reload and switching'
  )
end

local ok, err = xpcall(run, debug.traceback)
if not ok then
  io.stderr:write(err .. '\n')
  vim.cmd 'cquit 1'
else
  vim.cmd 'qa!'
end
