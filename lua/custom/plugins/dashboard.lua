return {
  'nvimdev/dashboard-nvim',
  event = 'VimEnter',
  opts = {
    theme = 'doom',
  },
  config = function()
    require('dashboard').setup {
      -- config
    }
  end,
  dependencies = { { 'nvim-tree/nvim-web-devicons' } },
}
