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
    FloatBorder = true,
    Identifier = true,
    IncSearch = true,
    LineNr = true,
    Search = true,
    String = true,
    Visual = true,
    BlinkCmpMenu = true,
    BlinkCmpMenuBorder = true,
    BlinkCmpMenuSelection = true,
    BlinkCmpLabel = true,
    BlinkCmpLabelMatch = true,
    BlinkCmpLabelDeprecated = true,
    BlinkCmpLabelDetail = true,
    BlinkCmpLabelDescription = true,
    BlinkCmpSource = true,
    BlinkCmpKind = true,
    BlinkCmpDocBorder = true,
    BlinkCmpDocSeparator = true,
    BlinkCmpSignatureHelpBorder = true,
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
  if reference then
    -- Intentional palette substitutions also apply to inherited and terminal colors.
    local colors = { [0xffdd33] = 0xe6c72e, [0x73d936] = 0x68c431 }
    for _, definitions in ipairs { expected.definitions, expected.resolved } do
      for _, attrs in pairs(definitions) do
        for _, key in ipairs { 'fg', 'bg', 'sp' } do
          if colors[attrs[key]] then
            attrs[key] = colors[attrs[key]]
          end
        end
      end
    end
    for key, color in pairs(expected.terminal) do
      if color == '#ffdd33' then
        expected.terminal[key] = '#e6c72e'
      elseif color == '#73d936' then
        expected.terminal[key] = '#68c431'
      end
    end
  end
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
  for _, name in ipairs {
    '@property',
    '@variable.member',
    'MatchParen',
    'ErrorMsg',
    'Folded',
    'DiffText',
    'DiagnosticVirtualTextWarn',
    'LineNr',
    'Search',
    'CurSearch',
    'Visual',
  } do
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
  assert(hl('Identifier').fg == hl('Normal').fg, 'Identifiers should not be brighter than body text')
  assert(not hl('String').italic and hl('Comment').italic, 'String and comment reading styles differ')
  assert(hl('CurSearch').bg == hl('Keyword').fg and hl('CurSearch').bg ~= hl('Search').bg, 'Current search needs distinct emphasis')
  assert(hl('Visual').fg == hl('Normal').fg, 'Selected syntax needs a readable uniform foreground')
  assert(contrast(hl('BlinkCmpMenuBorder').fg, hl('Pmenu').bg) >= 3, 'Completion border is too faint')
  for _, name in ipairs { 'BlinkCmpLabel', 'BlinkCmpLabelMatch', 'BlinkCmpLabelDescription', 'BlinkCmpLabelDetail', 'BlinkCmpKind' } do
    for _, background in ipairs { hl('Pmenu').bg, hl('PmenuSel').bg } do
      assert(contrast(hl(name).fg, background) >= 4.5, name .. ' is unreadable in a completion state')
    end
  end
  assert(luminance(hl('BlinkCmpLabelDescription').fg) < luminance(hl('BlinkCmpLabel').fg), 'Completion descriptions compete with labels')
  assert(not hl('BlinkCmpMenuSelection').fg, 'Completion selection foreground overrides matched letters')
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
