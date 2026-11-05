local function run()
  local function hex(value)
    assert(value, 'Expected a color but got nil')
    return string.format('#%06x', value)
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

  vim.cmd.colorscheme 'default'
  vim.cmd.colorscheme 'tsien-light'
  assert(vim.g.colors_name == 'tsien-light', 'Local light theme did not load')
  assert(vim.o.background == 'light', 'Light theme did not set background')
  local actual = snapshot()

  local function hl(name)
    return actual.resolved[name]
  end

  assert(hex(hl('Normal').bg) == '#fafafa', 'Unexpected light background')
  assert(hex(hl('Normal').fg) == '#383a42', 'Unexpected light foreground')

  for _, name in ipairs {
    'Comment',
    'LineNr',
    'StatusLine',
    'MatchParen',
    'ErrorMsg',
    'Folded',
    'DiffText',
    'Search',
    'Visual',
    'DiagnosticVirtualTextError',
    'DiagnosticVirtualTextWarn',
    'DiagnosticVirtualTextInfo',
    'DiagnosticVirtualTextHint',
  } do
    local attrs = hl(name)
    assert(contrast(attrs.fg, attrs.bg or hl('Normal').bg) >= 4.5, name .. ' has insufficient text contrast')
  end

  assert(hl('Comment').italic, 'Comments should stay italic')
  assert(not hl('String').italic, 'Strings should stay upright')
  assert(hl('Identifier').fg == hl('Normal').fg, 'Identifiers should share the body foreground')
  assert(hl('@variable.member').fg == hl('@property').fg, 'Field captures have inconsistent colors')
  assert(hl('Visual').fg == hl('Normal').fg, 'Selected syntax needs a readable uniform foreground')

  assert(hl('CurSearch').bg == hl('IncSearch').bg, 'Current search should use the incremental color')
  assert(hl('CurSearch').bg ~= hl('Search').bg, 'Current search needs distinct emphasis')
  assert(hl('DiffText').bg ~= hl('DiffChange').bg and hl('DiffText').underline, 'Changed characters need distinct emphasis')

  for _, severity in ipairs { 'Error', 'Warn', 'Info', 'Hint' } do
    assert(not hl('DiagnosticVirtualText' .. severity).bold, 'Inline diagnostics should not be bold')
  end
  assert(contrast(hl('DiagnosticSignWarn').fg, hl('Normal').bg) >= 3, 'Warning sign is too faint')

  assert(contrast(hl('BlinkCmpMenuBorder').fg, hl('Pmenu').bg) >= 3, 'Completion border is too faint')
  for _, name in ipairs {
    'BlinkCmpLabel',
    'BlinkCmpLabelMatch',
    'BlinkCmpLabelDescription',
    'BlinkCmpLabelDetail',
    'BlinkCmpKind',
  } do
    for _, background in ipairs { hl('Pmenu').bg, hl('PmenuSel').bg } do
      assert(contrast(hl(name).fg, background) >= 4.5, name .. ' is unreadable in a completion state')
    end
  end
  assert(not hl('BlinkCmpMenuSelection').fg, 'Completion selection foreground overrides matched labels')

  local expected_terminal = {
    '#383a42',
    '#e45649',
    '#50a14f',
    '#c18401',
    '#4078f2',
    '#a626a4',
    '#0184bc',
    '#a0a1a7',
    '#4f525e',
    '#e06c75',
    '#98c379',
    '#e5c07b',
    '#61afef',
    '#c678dd',
    '#56b6c2',
    '#ffffff',
  }
  for index, value in ipairs(expected_terminal) do
    assert(actual.terminal[index] == value, 'Terminal color differs at index ' .. (index - 1))
  end
  assert(
    actual.terminal.background == '#fafafa' and actual.terminal.foreground == '#383a42',
    'Terminal background or foreground differs'
  )

  for _, filetype in ipairs { 'help', 'qf' } do
    vim.api.nvim_exec_autocmds('FileType', { group = 'TsienLight', pattern = filetype })
    assert(vim.wo.winhighlight == 'Normal:NormalSB,SignColumn:SignColumnSB', 'Sidebar behavior differs')
  end

  require('theme.palette-light').bg = '#000000'
  package.loaded['theme.highlights'] = function()
    error 'Stale highlights module was reused'
  end
  vim.cmd.colorscheme 'tsien-light'
  assert(vim.deep_equal(snapshot(), actual), 'Reload did not restore source definitions')
  assert(#vim.api.nvim_get_autocmds { group = 'TsienLight' } == 4, 'Local autocmds duplicated')

  vim.cmd.colorscheme 'tsien-dark'
  assert(vim.g.colors_name == 'tsien-dark' and vim.o.background == 'dark', 'Dark theme did not restore background')
  assert(vim.fn.exists '#TsienLight' == 0, 'Light autocmds leaked after switching away')
  assert(vim.fn.exists '#TsienDark' == 1, 'Dark autocmds missing after switching')

  vim.cmd.colorscheme 'tsien-light'
  assert(vim.g.colors_name == 'tsien-light' and vim.o.background == 'light', 'Light theme did not restore background')
  assert(vim.deep_equal(snapshot(), actual), 'Switching back changed appearance')

  print(
    'THEME_LIGHT_TESTS_OK: '
      .. vim.tbl_count(actual.definitions)
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
