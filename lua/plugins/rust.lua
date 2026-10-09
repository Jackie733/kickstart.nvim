return {
  {
    'mrcjkb/rustaceanvim',
    version = '^9',
    -- rustaceanvim loads through ftplugin/rust.lua; register its runtime early.
    lazy = false,
    init = function()
      local cargo_home = vim.env.CARGO_HOME or vim.fs.joinpath(vim.uv.os_homedir(), '.cargo')
      local rustup_proxy = vim.fs.joinpath(cargo_home, 'bin', 'rust-analyzer')
      local rust_analyzer = vim.fn.executable(rustup_proxy) == 1 and rustup_proxy or 'rust-analyzer'

      vim.g.rustaceanvim = {
        tools = {},
        server = {
          cmd = { rust_analyzer },
          auto_attach = function(bufnr)
            return vim.bo[bufnr].buftype == ''
              and vim.api.nvim_buf_get_name(bufnr) ~= ''
              and vim.fn.executable(rust_analyzer) == 1
              and not require('core.buffer').is_bigfile(bufnr)
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
