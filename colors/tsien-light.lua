-- Tsien Light: Catppuccin Latte surfaces with One Light inspired syntax, no plugin dependencies.
-- The shared Tsien highlight structure is reused with a light palette and explicit overrides.
package.loaded['theme.palette-light'] = nil
package.loaded['theme.highlights-light'] = nil
package.loaded['theme.highlights'] = nil

-- A terminal background change reloads the active colorscheme. Follow the terminal
-- instead of restoring this theme's value; core.theme switches themes afterwards.
local background_reload = vim.g.tsien_background_reload
vim.g.tsien_background_reload = nil

if vim.g.colors_name then
  vim.cmd 'highlight clear'
end
vim.opt.termguicolors = true
-- Keep 'background' changes from reloading the previous colorscheme mid-switch.
vim.g.colors_name = nil
if not background_reload then
  vim.opt.background = 'light'
end
vim.g.colors_name = 'tsien-light'

local c = require 'theme.palette-light'
for group, attrs in pairs(require 'theme.highlights-light'(c)) do
  vim.api.nvim_set_hl(0, group, attrs)
end
vim.opt.guicursor:append 'a:Cursor/lCursor'

local terminal = {
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
for index, color in ipairs(terminal) do
  vim.g['terminal_color_' .. (index - 1)] = color
end
vim.g.terminal_color_background = c['bg']
vim.g.terminal_color_foreground = c['fg']

local group = vim.api.nvim_create_augroup('TsienLight', { clear = true })
vim.api.nvim_create_autocmd('ColorSchemePre', {
  group = group,
  callback = function()
    vim.api.nvim_del_augroup_by_id(group)
  end,
})
vim.api.nvim_create_autocmd('FileType', {
  group = group,
  pattern = { 'qf', 'help' },
  callback = function()
    vim.cmd.setlocal 'winhighlight=Normal:NormalSB,SignColumn:SignColumnSB'
  end,
})
vim.api.nvim_create_autocmd('ColorScheme', {
  group = group,
  callback = function()
    for _, name in ipairs(vim.fn.getcompletion('@lsp', 'highlight')) do
      vim.api.nvim_set_hl(0, name, {})
    end
  end,
})
