-- debug.lua
--
-- Shows how to use the DAP plugin to debug your code.
--
-- Primarily focused on configuring the debugger for Go, but can
-- be extended to other languages as well. That's why it's called
-- kickstart.nvim and not kitchen-sink.nvim ;)

return {
  -- NOTE: Yes, you can install new plugins here!
  'mfussenegger/nvim-dap',
  -- NOTE: And you can specify dependencies as well
  dependencies = {
    -- Creates a beautiful debugger UI
    'rcarriga/nvim-dap-ui',

    -- Required dependency for nvim-dap-ui
    'nvim-neotest/nvim-nio',

    -- Installs the debug adapters for you
    'mason-org/mason.nvim',
    'jay-babu/mason-nvim-dap.nvim',

    -- Add your own debuggers here
    'mfussenegger/nvim-dap-python',
  },
  keys = {
    -- Basic debugging keymaps, feel free to change to your liking!
    {
      '<F5>',
      function()
        require('dap').continue()
      end,
      desc = 'Debug: Start/Continue',
    },
    {
      '<F1>',
      function()
        require('dap').step_into()
      end,
      desc = 'Debug: Step Into',
    },
    {
      '<F2>',
      function()
        require('dap').step_over()
      end,
      desc = 'Debug: Step Over',
    },
    {
      '<F3>',
      function()
        require('dap').step_out()
      end,
      desc = 'Debug: Step Out',
    },
    {
      '<leader>db',
      function()
        require('dap').toggle_breakpoint()
      end,
      desc = 'Debug: Toggle Breakpoint',
    },
    {
      '<leader>dB',
      function()
        require('dap').set_breakpoint(vim.fn.input 'Breakpoint condition: ')
      end,
      desc = 'Debug: Set Breakpoint',
    },
    {
      '<leader>dPt',
      function()
        require('dap-python').test_method()
      end,
      desc = 'Debug: Python Test Method',
      ft = 'python',
    },
    {
      '<leader>dPc',
      function()
        require('dap-python').test_class()
      end,
      desc = 'Debug: Python Test Class',
      ft = 'python',
    },
    -- Toggle to see last session result. Without this, you can't see session output in case of unhandled exception.
    {
      '<F7>',
      function()
        require('dapui').toggle()
      end,
      desc = 'Debug: See last session result.',
    },
  },
  config = function()
    local dap = require 'dap'
    local dapui = require 'dapui'

    require('mason-nvim-dap').setup {
      -- Makes a best effort to setup the various debuggers with
      -- reasonable debug configurations
      automatic_installation = true,

      -- You can provide additional configuration to the handlers,
      -- see mason-nvim-dap README for more information
      handlers = {
        python = function() end,
      },

      -- You'll need to check that you have the required things installed
      -- online, please don't ask me how to install them :)
      ensure_installed = {
        'python',
        'js',
        'codelldb',
      },
    }

    -- Dap UI setup
    -- For more information, see |:help nvim-dap-ui|
    dapui.setup {
      -- Set icons to characters that are more likely to work in every terminal.
      --    Feel free to remove or use ones that you like more! :)
      --    Don't feel like these are good choices.
      icons = { expanded = '▾', collapsed = '▸', current_frame = '*' },
      controls = {
        icons = {
          pause = '⏸',
          play = '▶',
          step_into = '⏎',
          step_over = '⏭',
          step_out = '⏮',
          step_back = 'b',
          run_last = '▶▶',
          terminate = '⏹',
          disconnect = '⏏',
        },
      },
    }

    for _, adapter in ipairs { 'pwa-node', 'pwa-chrome' } do
      dap.adapters[adapter] = {
        type = 'server',
        host = 'localhost',
        port = '${port}',
        executable = {
          command = 'js-debug-adapter',
          args = { '${port}' },
        },
      }
    end

    dap.adapters.node = function(callback, config)
      config.type = 'pwa-node'
      callback(dap.adapters['pwa-node'])
    end

    local js_filetypes = { 'javascript', 'javascriptreact', 'typescript', 'typescriptreact', 'vue' }
    for _, language in ipairs(js_filetypes) do
      dap.configurations[language] = {
        {
          type = 'pwa-node',
          request = 'launch',
          name = 'Launch file',
          program = '${file}',
          cwd = '${workspaceFolder}',
          sourceMaps = true,
          runtimeExecutable = language:find 'typescript' and (vim.fn.executable 'tsx' == 1 and 'tsx' or 'ts-node') or nil,
          skipFiles = { '<node_internals>/**', 'node_modules/**' },
          resolveSourceMapLocations = { '${workspaceFolder}/**', '!**/node_modules/**' },
        },
        {
          type = 'pwa-node',
          request = 'attach',
          name = 'Attach process',
          processId = require('dap.utils').pick_process,
          cwd = '${workspaceFolder}',
          sourceMaps = true,
          skipFiles = { '<node_internals>/**', 'node_modules/**' },
        },
        {
          type = 'pwa-chrome',
          request = 'launch',
          name = 'Launch Chrome',
          url = function()
            return vim.fn.input('URL: ', 'http://localhost:3000')
          end,
          webRoot = '${workspaceFolder}',
          sourceMaps = true,
          skipFiles = { '<node_internals>/**', 'node_modules/**' },
        },
        {
          type = 'pwa-chrome',
          request = 'attach',
          name = 'Attach Chrome',
          port = 9222,
          webRoot = '${workspaceFolder}',
          sourceMaps = true,
          skipFiles = { '<node_internals>/**', 'node_modules/**' },
        },
      }
    end

    dap.listeners.after.event_initialized['dapui_config'] = dapui.open
    dap.listeners.before.event_terminated['dapui_config'] = dapui.close
    dap.listeners.before.event_exited['dapui_config'] = dapui.close

    local project = require 'core.project'
    local function python_path()
      return project.python_path(0)
    end

    local function debugpy_adapter()
      if vim.fn.executable 'debugpy-adapter' == 1 then
        return 'debugpy-adapter'
      end

      local mason_python = vim.fn.stdpath 'data' .. '/mason/packages/debugpy/venv/bin/python'
      if vim.fn.executable(mason_python) == 1 then
        return mason_python
      end

      return python_path()
    end

    require('dap-python').setup(debugpy_adapter())

    dap.configurations.python = {
      {
        type = 'python',
        request = 'launch',
        name = 'Launch file',
        program = '${file}',
        cwd = function()
          return project.python_root(0) or vim.fn.getcwd()
        end,
        pythonPath = python_path,
        justMyCode = false,
      },
      {
        type = 'python',
        request = 'launch',
        name = 'Launch file with args',
        program = '${file}',
        cwd = function()
          return project.python_root(0) or vim.fn.getcwd()
        end,
        args = function()
          return vim.split(vim.fn.input 'Arguments: ', ' ', { trimempty = true })
        end,
        pythonPath = python_path,
        justMyCode = false,
      },
      {
        type = 'python',
        request = 'launch',
        name = 'Launch module',
        module = function()
          return vim.fn.input 'Module: '
        end,
        cwd = function()
          return project.python_root(0) or vim.fn.getcwd()
        end,
        pythonPath = python_path,
        justMyCode = false,
      },
      {
        type = 'python',
        request = 'launch',
        name = 'Pytest current file',
        module = 'pytest',
        args = function()
          return { vim.fn.expand '%' }
        end,
        cwd = function()
          return project.python_root(0) or vim.fn.getcwd()
        end,
        pythonPath = python_path,
        justMyCode = false,
      },
      {
        type = 'python',
        request = 'attach',
        name = 'Attach debugpy localhost:5678',
        connect = {
          host = '127.0.0.1',
          port = 5678,
        },
        cwd = function()
          return project.python_root(0) or vim.fn.getcwd()
        end,
        pythonPath = python_path,
        justMyCode = false,
      },
    }
  end,
}
