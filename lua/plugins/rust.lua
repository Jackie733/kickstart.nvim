return {
  {
    'mrcjkb/rustaceanvim',
    version = '^5',
    ft = 'rust',
    init = function()
      vim.g.rustaceanvim = {
        tools = {},
        server = {
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
                allFeatures = true,
                loadOutDirsFromCheck = true,
                buildScripts = { enable = true },
              },
              checkOnSave = {
                allFeatures = true,
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
