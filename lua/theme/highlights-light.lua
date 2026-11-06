-- One Light inspired overrides on top of the shared Tsien highlight structure.
-- Syntax roles follow Atom One Light: purple keywords, blue functions, gold types,
-- orange constants and numbers, green strings, red tags, and cyan escapes.
return function(c)
  local groups = require('theme.highlights')(c)

  local overrides = {
    ['@constant.builtin'] = { link = 'GruberDarkerWisteria' },
    ['@comment.documentation'] = { italic = true, link = 'Comment' },
    ['@comment.luadoc'] = { link = '@comment.documentation' },
    ['@function.builtin'] = { link = 'GruberDarkerNiagara' },
    ['@punctuation.bracket'] = { fg = c['fg'] },
    ['@punctuation.special'] = { fg = c['red'] },
    ['@string.escape'] = { fg = c['cyan'] },
    ['@string.regex'] = { fg = c['cyan'] },
    ['@string.special'] = { fg = c['wisteria'] },
    ['@tag.attribute'] = { fg = c['wisteria'] },
    ['@type.builtin'] = { link = 'GruberDarkerQuartz' },
    ['@type.definition'] = { bold = true, fg = c['quartz'] },
    ['@variable.builtin'] = { fg = c['red'] },
    ['Boolean'] = { bold = true, fg = c['wisteria'] },
    ['Constant'] = { fg = c['wisteria'] },
    ['SpecialComment'] = { bold = true, fg = c['brown'] },
    ['Tag'] = { fg = c['red'] },
    ['Underlined'] = { fg = c['niagara'], underline = true },
    ['markdownItalic'] = { fg = c['yellow'], italic = true },

    -- UI roles that assume a dark background in the shared definitions.
    ['Cursor'] = { bg = c['cursor'] },
    ['CursorIM'] = { bg = c['cursor'], fg = c['none'] },
    ['TermCursor'] = { bg = c['cursor'] },
    ['lCursor'] = { bg = c['cursor'], fg = c['none'] },
    ['ErrorMsg'] = { bg = c['red'], fg = c['white'], bold = true },
    ['WildMenu'] = { bg = c['quartz'], fg = c['fg+2'] },
    ['MatchParen'] = { bg = c['bg+2'], fg = c['fg'], bold = true, underline = true },
    ['Search'] = { bg = c['search-bg'], fg = c['fg'] },
    ['IncSearch'] = { bg = c['quartz'], fg = c['fg+2'] },
    ['Todo'] = { bg = c['search-bg'], fg = c['fg'], bold = true },
    ['StatusLine'] = { bg = c['bg+1'], fg = c['fg'] },
    ['StatusLineNC'] = { bg = c['bg+1'], fg = c['menu-muted'] },
    ['TelescopeTitle'] = { bold = true, fg = c['fg+2'] },
    ['PmenuSbar'] = { bg = c['bg+2'] },
    ['PmenuThumb'] = { bg = c['bg+4'] },
    ['VertSplit'] = { bg = c['bg'], fg = c['bg+1'] },
    ['WinSeparator'] = { bg = c['bg'], fg = c['bg+1'] },
    ['NeoTreeVertSplit'] = { bg = c['bg'], fg = c['bg+1'] },
    ['NeoTreeWinSeparator'] = { bg = c['bg'], fg = c['bg+1'] },
    ['SpecialKey'] = { fg = c['menu-muted'] },

    -- Diff backgrounds are tinted for light windows rather than reusing raised dark surfaces.
    ['DiffAdd'] = { bg = c['diff-add-bg'], fg = c['diff-add-fg'] },
    ['DiffChange'] = { bg = c['diff-change-bg'], fg = c['diff-change-fg'] },
    ['DiffDelete'] = { bg = c['diff-delete-bg'], fg = c['diff-delete-fg'] },
    ['DiffText'] = { bg = c['diff-text-bg'], fg = c['fg'], bold = true, underline = true },

    -- Gutter signs and Neo-tree git labels must not inherit diff line backgrounds.
    ['GitSignsAdd'] = { fg = c['diff-add-fg'] },
    ['GitSignsChange'] = { fg = c['diff-change-fg'] },
    ['GitSignsDelete'] = { fg = c['diff-delete-fg'] },
    ['NeoTreeGitAdded'] = { fg = c['diff-add-fg'] },
    ['NeoTreeGitModified'] = { fg = c['diff-change-fg'] },
    ['NeoTreeGitDeleted'] = { fg = c['diff-delete-fg'] },

    -- Severity colors: gold warnings, cyan information and hints, red errors.
    -- Warning text uses the darker orange so inline and floating text stay readable;
    -- gutter signs keep the gold accent.
    ['DiagnosticWarn'] = { bold = true, fg = c['wisteria'] },
    ['DiagnosticInfo'] = { bold = true, fg = c['cyan-dark'] },
    ['DiagnosticHint'] = { fg = c['cyan-dark'] },
    ['DiagnosticVirtualTextWarn'] = { fg = c['wisteria'] },
    ['DiagnosticVirtualTextInfo'] = { fg = c['cyan-dark'] },
    ['DiagnosticVirtualTextHint'] = { fg = c['cyan-dark'] },
    ['DiagnosticSignWarn'] = { fg = c['quartz'], reverse = false },
    ['DiagnosticSignInfo'] = { fg = c['cyan'], reverse = false },
    ['DiagnosticSignHint'] = { fg = c['cyan'], reverse = false },
    ['DiagnosticUnderlineWarn'] = { sp = c['quartz'], undercurl = true },
    ['DiagnosticUnderlineInfo'] = { sp = c['cyan'], undercurl = true },
    ['DiagnosticUnderlineHint'] = { sp = c['cyan'], undercurl = true },

    -- The shared palette swaps yellow and wisteria roles for One Light hues,
    -- so explicit names restore the expected icon and rainbow colors.
    ['MiniIconsAzure'] = { fg = c['niagara'] },
    ['MiniIconsBlue'] = { fg = c['niagara'] },
    ['MiniIconsCyan'] = { fg = c['cyan'] },
    ['MiniIconsGreen'] = { fg = c['green'] },
    ['MiniIconsGrey'] = { fg = c['menu-muted'] },
    ['MiniIconsOrange'] = { fg = c['wisteria'] },
    ['MiniIconsPurple'] = { fg = c['yellow'] },
    ['MiniIconsRed'] = { fg = c['red'] },
    ['MiniIconsYellow'] = { fg = c['quartz'] },
    ['RainbowDelimiterBlue'] = { fg = c['niagara'] },
    ['RainbowDelimiterCyan'] = { fg = c['cyan'] },
    ['RainbowDelimiterGreen'] = { fg = c['green'] },
    ['RainbowDelimiterOrange'] = { fg = c['wisteria'] },
    ['RainbowDelimiterRed'] = { fg = c['red'] },
    ['RainbowDelimiterViolet'] = { fg = c['yellow'] },
    ['RainbowDelimiterYellow'] = { fg = c['quartz'] },
    ['CompileModeWarning'] = { fg = c['quartz'] },
  }

  for group, attrs in pairs(overrides) do
    groups[group] = attrs
  end
  return groups
end
