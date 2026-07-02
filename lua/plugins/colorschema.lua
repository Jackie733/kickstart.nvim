return {
  {
    'rebelot/kanagawa.nvim',
    lazy = false,
    priority = 1000,
    config = function()
      require('kanagawa').setup {
        transparent = false,
        overrides = function(colors)
          return require('core.theme').kanagawa_overrides(colors)
        end,
      }
      vim.o.background = 'dark'
      vim.cmd.colorscheme 'kanagawa-wave'
    end,
  },
}
