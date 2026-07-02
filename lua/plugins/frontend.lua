return {
  {
    'windwp/nvim-ts-autotag',
    ft = { 'html', 'javascriptreact', 'typescriptreact', 'vue' },
    opts = {
      opts = {
        enable_close = true,
        enable_rename = true,
        enable_close_on_slash = false,
      },
    },
  },
  {
    'NvChad/nvim-colorizer.lua',
    ft = {
      'css',
      'scss',
      'html',
      'javascriptreact',
      'typescriptreact',
      'vue',
    },
    opts = {
      filetypes = {
        'css',
        'scss',
        'html',
        'javascriptreact',
        'typescriptreact',
        'vue',
      },
      user_default_options = {
        mode = 'background',
        tailwind = true,
        RGB = true,
        RRGGBB = true,
        RRGGBBAA = true,
        rgb_fn = true,
        hsl_fn = true,
        css = true,
        css_fn = true,
      },
    },
  },
}
