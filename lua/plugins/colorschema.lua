-- 修改这里即可切换默认主题：'gruber-darker' / 'kanagawa-wave' / 'kanagawa-dragon' / 'kanagawa-lotus'
local colorscheme = 'gruber-darker'

return {
  {
    'blazkowolf/gruber-darker.nvim',
    lazy = false,
    priority = 1000,
    -- 可在这里覆盖主题默认选项，例如 italic = { comments = false }。
    opts = {},
    config = function(_, opts)
      require('gruber-darker').setup(opts)
      vim.cmd.colorscheme(colorscheme)
    end,
    dependencies = { 'rebelot/kanagawa.nvim' },
  },
  {
    'rebelot/kanagawa.nvim',
    lazy = false,
    priority = 1000,
    opts = {},
  },
}
