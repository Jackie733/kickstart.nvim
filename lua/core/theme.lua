local M = {}

function M.kanagawa_overrides(colors)
  local theme = colors.theme
  local ui = theme.ui
  local bg = ui.bg
  local bg_dim = ui.bg_dim or ui.bg_m3 or bg
  local bg_float = ui.float.bg or ui.bg_p1 or bg
  local bg_popup = ui.bg_p1 or bg_float
  local bg_selection = ui.bg_p2 or ui.bg_m1 or bg_popup
  local border = ui.float.fg_border

  return {
    Normal = { bg = bg },
    NormalNC = { bg = bg },
    SignColumn = { bg = bg },
    FoldColumn = { bg = bg },
    EndOfBuffer = { bg = bg },
    StatusLine = { bg = bg_dim },
    StatusLineNC = { bg = bg_dim },
    NormalFloat = { bg = bg_float },
    FloatBorder = { bg = bg_float, fg = border },
    FloatTitle = { bg = bg_float },
    NoiceCmdlinePopup = { bg = bg_float },
    NoiceCmdlinePopupBorder = { bg = bg_float, fg = border },
    NoiceCmdlinePopupTitle = { bg = bg_float },
    NoicePopup = { bg = bg_float },
    NoicePopupBorder = { bg = bg_float, fg = border },
    FidgetTitle = { bg = bg_float },
    FidgetTask = { bg = bg_float },
    TelescopeNormal = { bg = bg_dim },
    TelescopeBorder = { bg = bg_dim, fg = border },
    TelescopePromptNormal = { bg = bg_popup },
    TelescopePromptBorder = { bg = bg_popup, fg = border },
    TelescopeResultsNormal = { bg = bg_dim },
    TelescopeResultsBorder = { bg = bg_dim, fg = border },
    TelescopePreviewNormal = { bg = bg_dim },
    TelescopePreviewBorder = { bg = bg_dim, fg = border },
    Pmenu = { fg = ui.shade0, bg = bg_popup, blend = 0 },
    PmenuSel = { fg = 'none', bg = bg_selection },
    PmenuSbar = { bg = bg_popup },
    PmenuThumb = { bg = bg_selection },
    NotifyBackground = { bg = bg_float },
    LazyNormal = { bg = bg_float },
    LazyBackdrop = { bg = bg_dim },
    WhichKeyNormal = { bg = bg_float },
    WhichKeyBorder = { bg = bg_float, fg = border },
    BlinkCmpMenu = { bg = bg_popup },
    BlinkCmpMenuBorder = { bg = bg_popup, fg = border },
    BlinkCmpDoc = { bg = bg_float },
    BlinkCmpDocBorder = { bg = bg_float, fg = border },
    BlinkCmpSignatureHelp = { bg = bg_float },
    BlinkCmpSignatureHelpBorder = { bg = bg_float, fg = border },
    TabLine = { bg = bg_dim },
    TabLineFill = { bg = bg },
    TabLineSel = { bg = bg_selection },
  }
end

return M
