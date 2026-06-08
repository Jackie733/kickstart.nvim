return {
  {
    'rebelot/kanagawa.nvim',
    lazy = false,
    priority = 1000,
    config = function()
      require('kanagawa').setup {
        transparent = true, -- 启用透明背景
        colors = {
          theme = {
            all = {
              ui = {
                bg_gutter = 'none', -- 移除行号区域背景
              },
            },
          },
        },
        overrides = function(colors)
          return require('core.theme').kanagawa_overrides(colors)
        end,
      }
      vim.o.background = 'dark'
      vim.cmd.colorscheme 'kanagawa-wave'
    end,
  },
}
