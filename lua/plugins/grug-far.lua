-- 全局搜索替换插件，类似 VSCode 的搜索替换功能
return {
  'MagicDuck/grug-far.nvim',
  keys = {
    {
      '<leader>rr',
      function()
        require('grug-far').open()
      end,
      desc = '[R]eplace in project',
    },
    {
      '<leader>rw',
      function()
        require('grug-far').open { prefills = { search = vim.fn.expand '<cword>' } }
      end,
      desc = '[R]eplace current [W]ord',
    },
    {
      '<leader>rf',
      function()
        require('grug-far').open { prefills = { paths = vim.fn.expand '%' } }
      end,
      mode = { 'n', 'v' },
      desc = '[R]eplace in current [F]ile',
    },
  },
  config = function()
    require('grug-far').setup {
      -- 配置选项
      headerMaxWidth = 80,
      -- 推荐使用 ripgrep 作为搜索引擎
      engines = {
        ripgrep = {
          path = 'rg',
          extraArgs = '',
        },
      },
      -- 窗口配置
      windowCreationCommand = 'vsplit',
      -- 启用图标
      icons = {
        enabled = vim.g.have_nerd_font,
      },
    }
  end,
}
