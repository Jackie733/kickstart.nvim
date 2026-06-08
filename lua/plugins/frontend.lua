return {
  {
    'windwp/nvim-ts-autotag',
    event = { 'BufReadPost', 'BufNewFile' },
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
    event = { 'BufReadPost', 'BufNewFile' },
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
