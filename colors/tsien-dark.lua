-- Local baseline of gruber-darker.nvim at 35cb97959ef01f7193c94c404c13ddb3d4346654.
-- Derived from blazkowolf/gruber-darker.nvim; see lua/theme/LICENSE.gruber-darker.
package.loaded['theme.palette'] = nil
package.loaded['theme.highlights'] = nil

if vim.g.colors_name then
  vim.cmd 'highlight clear'
end
vim.opt.termguicolors = true
vim.g.colors_name = 'tsien-dark'

local c = require 'theme.palette'
for group, attrs in pairs(require 'theme.highlights'(c)) do
  vim.api.nvim_set_hl(0, group, attrs)
end
vim.opt.guicursor:append 'a:Cursor/lCursor'

local terminal = { c['bg+1'], c['red+1'], c.green, c.yellow, c.niagara, c.wisteria, c.niagara, c.fg }
for index, color in ipairs(terminal) do
  vim.g['terminal_color_' .. (index - 1)] = color
  vim.g['terminal_color_' .. (index + 7)] = color
end
vim.g.terminal_color_background = c['bg+1']
vim.g.terminal_color_foreground = c.white

-- Preserve upstream sidebar and semantic-highlight behavior for an exact baseline.
local group = vim.api.nvim_create_augroup('TsienDark', { clear = true })
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
