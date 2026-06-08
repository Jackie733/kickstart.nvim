local M = {}

function M.kanagawa_overrides(colors)
  local theme = colors.theme
  return {
    Normal = { bg = 'none' },
    NormalNC = { bg = 'none' },
    StatusLine = { bg = 'none' },
    StatusLineNC = { bg = 'none' },
    NormalFloat = { bg = 'none' },
    FloatBorder = { bg = 'none' },
    FloatTitle = { bg = 'none' },
    NoiceCmdlinePopup = { bg = 'none' },
    NoiceCmdlinePopupBorder = { bg = 'none' },
    NoiceCmdlinePopupTitle = { bg = 'none' },
    NoicePopup = { bg = 'none' },
    NoicePopupBorder = { bg = 'none' },
    FidgetTitle = { bg = 'none' },
    FidgetTask = { bg = 'none' },
    TelescopeNormal = { bg = 'none' },
    TelescopeBorder = { bg = 'none' },
    TelescopePromptNormal = { bg = 'none' },
    TelescopePromptBorder = { bg = 'none' },
    TelescopeResultsNormal = { bg = 'none' },
    TelescopeResultsBorder = { bg = 'none' },
    TelescopePreviewNormal = { bg = 'none' },
    TelescopePreviewBorder = { bg = 'none' },
    Pmenu = { fg = theme.ui.shade0, bg = 'none', blend = 0 },
    PmenuSel = { fg = 'none', bg = theme.ui.bg_p2 },
    PmenuSbar = { bg = 'none' },
    PmenuThumb = { bg = theme.ui.bg_p2 },
    NotifyBackground = { bg = 'none' },
    LazyNormal = { bg = 'none' },
    LazyBackdrop = { bg = 'none' },
    WhichKeyNormal = { bg = 'none' },
    WhichKeyBorder = { bg = 'none', fg = theme.ui.float.fg_border },
    BlinkCmpMenu = { bg = 'none' },
    BlinkCmpMenuBorder = { bg = 'none' },
    BlinkCmpDoc = { bg = 'none' },
    BlinkCmpDocBorder = { bg = 'none' },
    BlinkCmpSignatureHelp = { bg = 'none' },
    BlinkCmpSignatureHelpBorder = { bg = 'none' },
    TabLine = { bg = 'none' },
    TabLineFill = { bg = 'none' },
    TabLineSel = { bg = 'none' },
  }
end

return M
