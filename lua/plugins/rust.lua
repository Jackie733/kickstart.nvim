return {
  {
    'mrcjkb/rustaceanvim',
    version = '^9',
    -- rustaceanvim loads through ftplugin/rust.lua; register its runtime early.
    lazy = false,
    init = function()
      local environment = require 'core.environment'

      vim.g.rustaceanvim = {
        tools = {},
        server = {
          cmd = function()
            return { environment.rust_analyzer() or 'rust-analyzer' }
          end,
          auto_attach = function(bufnr)
            return vim.bo[bufnr].buftype == ''
              and vim.api.nvim_buf_get_name(bufnr) ~= ''
              and not require('core.buffer').is_bigfile(bufnr)
              and environment.rust_analyzer(bufnr) ~= nil
          end,
          on_attach = function(client, bufnr)
            local map = function(keys, func, desc)
              vim.keymap.set('n', keys, func, { buffer = bufnr, desc = 'Rust: ' .. desc })
            end

            map('<leader>ca', function()
              vim.cmd.RustLsp 'codeAction'
            end, 'Code Action')
            map('<leader>dr', function()
              vim.cmd.RustLsp 'debuggables'
            end, 'Debug Runnables')
            map('<leader>cC', function()
              vim.cmd 'botright 12new'
              vim.fn.jobstart({ 'cargo', 'clippy', '--workspace', '--all-targets', '--', '--no-deps' }, {
                cwd = client.config.root_dir,
                term = true,
              })
              vim.cmd.startinsert()
            end, 'Run Clippy')
          end,
          default_settings = {
            ['rust-analyzer'] = {
              cargo = {
                buildScripts = { enable = true },
              },
              check = {
                command = 'check',
              },
              files = {
                excludeDirs = { '.git', '.jj', 'node_modules', 'target', '.venv' },
              },
              procMacro = {
                enable = true,
                ignored = {
                  ['async-trait'] = { 'async_trait' },
                  ['napi-derive'] = { 'napi' },
                  ['async-recursion'] = { 'async_recursion' },
                },
              },
            },
          },
        },
        dap = { autoload_configurations = false },
      }
    end,
  },
}
