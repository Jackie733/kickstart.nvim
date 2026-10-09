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

  local changed = {
    ['@property'] = true,
    ['@variable.member'] = true,
    DiagnosticVirtualTextError = true,
    DiagnosticVirtualTextWarn = true,
    DiagnosticVirtualTextInfo = true,
    DiagnosticVirtualTextHint = true,
    DiffAdd = true,
    DiffChange = true,
    DiffDelete = true,
    DiffText = true,
    ErrorMsg = true,
    Folded = true,
    MatchParen = true,
    javaScript = true,
  }
  local function affected(name, definitions)
    if changed[name] then
      return true
    end
    local attrs = definitions[name]
    return attrs and attrs.link and affected(attrs.link, definitions) or false
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
    if not reference or not changed[name] then
      assert(vim.deep_equal(attrs, actual.definitions[name]), 'Definition differs: ' .. name)
    end
    if not reference or not affected(name, expected.definitions) then
      assert(vim.deep_equal(expected.resolved[name], actual.resolved[name]), 'Resolved appearance differs: ' .. name)
    end
  end
  for name, attrs in pairs(actual.definitions) do
    if not reference or not changed[name] then
      assert(vim.deep_equal(attrs, expected.definitions[name]), 'Extra or different definition: ' .. name)
    end
  end

  -- Readability and hierarchy contracts for intentional deviations from upstream.
  local function hl(name)
    return actual.resolved[name]
  end
  local function luminance(rgb)
    local r, g, b = math.floor(rgb / 65536), math.floor(rgb / 256) % 256, rgb % 256
    local function linear(value)
      value = value / 255
      return value <= 0.04045 and value / 12.92 or ((value + 0.055) / 1.055) ^ 2.4
    end
    return 0.2126 * linear(r) + 0.7152 * linear(g) + 0.0722 * linear(b)
  end
  local function contrast(fg, bg)
    local a, b = luminance(fg), luminance(bg)
    return (math.max(a, b) + 0.05) / (math.min(a, b) + 0.05)
  end
  for _, name in ipairs { '@property', '@variable.member', 'MatchParen', 'ErrorMsg', 'Folded', 'DiffText', 'DiagnosticVirtualTextWarn' } do
    local attrs = hl(name)
    assert(contrast(attrs.fg, attrs.bg or hl('Normal').bg) >= 4.5, name .. ' has insufficient text contrast')
  end
  assert(hl('@variable.member').fg == hl('@property').fg, 'Field captures have inconsistent colors')
  for _, severity in ipairs { 'Error', 'Warn', 'Info', 'Hint' } do
    assert(not hl('DiagnosticVirtualText' .. severity).bold, 'Inline diagnostics should not be bold')
  end
  assert(luminance(hl('DiagnosticVirtualTextWarn').fg) < luminance(hl('Keyword').fg), 'Inline warning competes with keywords')
  assert(hl('DiagnosticSignWarn').fg == hl('Keyword').fg, 'Warning sign lost its emphasis')
  assert(hl('DiffText').bg ~= hl('DiffChange').bg and hl('DiffText').underline, 'Changed characters need distinct emphasis')
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
