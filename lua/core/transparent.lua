local M = {}

local groups = {
  'Normal',
  'NormalNC',
  'EndOfBuffer',
  'SignColumn',
  'FoldColumn',
  'LineNr',
  'LineNrAbove',
  'LineNrBelow',
  'CursorLineSign',
  'CursorLineFold',
  'GitSignsAdd',
  'GitSignsChange',
  'GitSignsDelete',
  'GitSignsStagedAdd',
  'GitSignsStagedChange',
  'GitSignsStagedDelete',
  'GitSignsStagedChangedelete',
  'GitSignsStagedTopdelete',
  'GitSignsStagedUntracked',
  'StatusLine',
  'StatusLineNC',
  'TabLine',
  'TabLineFill',
  'TabLineSel',
  'WinBar',
  'WinBarNC',
  'MsgArea',
  'BlinkCmpMenu',
  'BlinkCmpMenuBorder',
  'BlinkCmpScrollBarGutter',
  'BlinkCmpScrollBarThumb',
  'BlinkCmpDoc',
  'BlinkCmpDocBorder',
  'BlinkCmpDocCursorLine',
  'BlinkCmpDocSeparator',
  'BlinkCmpCursorLineDocumentationHack',
  'BlinkCmpLabelDescription',
  'BlinkCmpLabelDetail',
  'BlinkCmpSource',
  'BlinkCmpSignatureHelp',
  'BlinkCmpSignatureHelpBorder',
  'BlinkCmpCursorLineSignatureHelpHack',
}

local prefixes = {
  'BufferLine',
  'DiagnosticSign',
  'MiniClue',
  'NeoTree',
  'SnacksDashboard',
  'WhichKey',
}

local derived_groups = {
  TsienLspHover = 'NormalFloat',
  TsienLspHoverBorder = 'FloatBorder',
}

local function clear_bg(group)
  local ok, hl = pcall(vim.api.nvim_get_hl, 0, { name = group, link = false })
  if not ok then
    return
  end

  hl.bg = 'NONE'
  hl.ctermbg = 'NONE'
  vim.api.nvim_set_hl(0, group, hl)
end

local function clear_prefix(prefix)
  local ok, highlights = pcall(vim.api.nvim_get_hl, 0, {})
  if not ok then
    return
  end

  for group in pairs(highlights) do
    if group:sub(1, #prefix) == prefix then
      clear_bg(group)
    end
  end
end

local function clear_bg_from(group, source)
  local ok, hl = pcall(vim.api.nvim_get_hl, 0, { name = source, link = false })
  if not ok then
    return
  end

  hl.bg = 'NONE'
  hl.ctermbg = 'NONE'
  vim.api.nvim_set_hl(0, group, hl)
end

function M.is_enabled()
  return vim.g.tsien_transparent_background == true
end

function M.apply()
  if not M.is_enabled() then
    return
  end

  for _, group in ipairs(groups) do
    clear_bg(group)
  end

  for _, prefix in ipairs(prefixes) do
    clear_prefix(prefix)
  end

  for group, source in pairs(derived_groups) do
    clear_bg_from(group, source)
  end
end

local function reload_colorscheme()
  local colors_name = vim.g.colors_name
  if type(colors_name) ~= 'string' or colors_name == '' then
    return
  end

  pcall(vim.cmd.colorscheme, colors_name)
end

function M.set(enabled)
  vim.g.tsien_transparent_background = enabled == true

  if M.is_enabled() then
    M.apply()
    vim.schedule(M.apply)
  else
    reload_colorscheme()
  end
end

function M.enable()
  M.set(true)
  vim.notify('Enabled transparent background', vim.log.levels.INFO)
end

function M.disable()
  M.set(false)
  vim.notify('Disabled transparent background', vim.log.levels.INFO)
end

function M.toggle()
  if M.is_enabled() then
    M.disable()
  else
    M.enable()
  end
end

function M.setup()
  local group = vim.api.nvim_create_augroup('tsien-transparent-background', { clear = true })

  vim.api.nvim_create_user_command('TsienTransparentEnable', M.enable, { desc = 'Enable transparent background' })
  vim.api.nvim_create_user_command('TsienTransparentDisable', M.disable, { desc = 'Disable transparent background' })
  vim.api.nvim_create_user_command('TsienTransparentToggle', M.toggle, { desc = 'Toggle transparent background' })

  vim.api.nvim_create_autocmd({ 'ColorScheme', 'VimEnter' }, {
    group = group,
    desc = 'Apply transparent background highlights',
    callback = function()
      vim.schedule(M.apply)
    end,
  })

  vim.api.nvim_create_autocmd('User', {
    group = group,
    pattern = { 'VeryLazy', 'LazyLoad' },
    desc = 'Reapply transparent background after lazy plugin setup',
    callback = function()
      vim.schedule(M.apply)
    end,
  })

  vim.schedule(M.apply)
end

return M
