-- You can add your own plugins here or in other files in this directory!
--  I promise not to create any merge conflicts in this directory :)
--
-- See the kickstart.nvim README for more information
return {
  {
    'folke/snacks.nvim',
    priority = 1000,
    lazy = false,
    opts = {},
    config = function(_, opts)
      require('snacks').setup(opts)
    end,
  },
}
