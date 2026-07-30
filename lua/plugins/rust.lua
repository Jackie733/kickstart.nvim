return {
  {
    'mrcjkb/rustaceanvim',
    version = '^9',
    ft = 'rust',
    init = function()
      vim.g.rustaceanvim = {
        tools = {},
        server = {
          cmd = { 'rustup', 'run', 'stable', 'rust-analyzer' },
          on_attach = function(_, bufnr)
            local map = function(keys, func, desc)
              vim.keymap.set('n', keys, func, { buffer = bufnr, desc = 'Rust: ' .. desc })
            end

            map('<leader>ca', function()
              vim.cmd.RustLsp 'codeAction'
            end, 'Code Action')
            map('<leader>dr', function()
              vim.cmd.RustLsp 'debuggables'
            end, 'Debug Runnables')
          end,
          default_settings = {
            ['rust-analyzer'] = {
              cargo = {
                features = 'all',
                buildScripts = { enable = true },
              },
              checkOnSave = true,
              check = {
                command = 'clippy',
                extraArgs = { '--no-deps' },
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
        dap = {},
      }
    end,
  },
}
