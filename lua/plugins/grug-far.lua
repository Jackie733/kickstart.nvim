-- 全局搜索替换插件，类似 VSCode 的搜索替换功能
return {
  'MagicDuck/grug-far.nvim',
  keys = {
    {
      '<leader>sr',
      function()
        require('grug-far').open()
      end,
      desc = '[S]earch and [R]eplace',
    },
    {
      '<leader>sw',
      function()
        require('grug-far').open({ prefills = { search = vim.fn.expand('<cword>') } })
      end,
      desc = '[S]earch and replace current [W]ord',
    },
    {
      '<leader>sf',
      function()
        require('grug-far').open({ prefills = { paths = vim.fn.expand('%') } })
      end,
      mode = { 'n', 'v' },
      desc = '[S]earch and replace in current [F]ile',
    },
  },
  config = function()
    require('grug-far').setup({
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
    })
  end,
}
