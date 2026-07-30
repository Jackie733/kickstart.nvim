return {
  {
    'linux-cultist/venv-selector.nvim',
    ft = 'python',
    cmd = {
      'VenvSelect',
    },
    dependencies = {
      'neovim/nvim-lspconfig',
      'nvim-telescope/telescope.nvim',
      'mfussenegger/nvim-dap-python',
    },
    keys = {
      { '<leader>cv', '<cmd>VenvSelect<cr>', desc = '[C]ode Select Python VirtualEnv', ft = 'python' },
    },
    opts = {
      options = {
        notify_user_on_venv_activation = true,
        override_notify = false,
      },
    },
  },
  {
    'nvim-neotest/neotest',
    dependencies = {
      'nvim-lua/plenary.nvim',
      'nvim-neotest/nvim-nio',
      'nvim-treesitter/nvim-treesitter',
      'nvim-neotest/neotest-python',
    },
    keys = {
      {
        '<leader>pn',
        function()
          require('neotest').run.run()
        end,
        desc = '[P]ython Test Nearest',
      },
      {
        '<leader>pf',
        function()
          require('neotest').run.run(vim.fn.expand '%')
        end,
        desc = '[P]ython Test File',
      },
      {
        '<leader>pa',
        function()
          require('neotest').run.run(vim.uv.cwd())
        end,
        desc = '[P]ython Test All',
      },
      {
        '<leader>pd',
        function()
          require('neotest').run.run { strategy = 'dap' }
        end,
        desc = '[P]ython Debug Nearest Test',
      },
      {
        '<leader>pl',
        function()
          require('neotest').run.run_last()
        end,
        desc = '[P]ython Test Last',
      },
      {
        '<leader>po',
        function()
          require('neotest').output.open { enter = true, auto_close = true }
        end,
        desc = '[P]ython Test Output',
      },
      {
        '<leader>ps',
        function()
          require('neotest').summary.toggle()
        end,
        desc = '[P]ython Test Summary',
      },
    },
    opts = function()
      local project = require 'core.project'

      return {
        adapters = {
          require 'neotest-python' {
            dap = {
              justMyCode = false,
            },
            python = function()
              return project.python_path(0)
            end,
          },
        },
      }
    end,
    config = function(_, opts)
      require('neotest').setup(opts)
    end,
  },
}
