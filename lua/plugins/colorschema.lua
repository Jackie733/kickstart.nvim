return {
  {
    'rebelot/kanagawa.nvim',
    lazy = false,
    priority = 1000,
    config = function()
      require('kanagawa').setup {
        transparent = true, -- 启用透明背景
        colors = {
          theme = {
            all = {
              ui = {
                bg_gutter = 'none', -- 移除行号区域背景
              },
            },
          },
        },
        overrides = function(colors)
          local theme = colors.theme
          return {
            -- 基础背景透明
            Normal = { bg = 'none' },
            NormalNC = { bg = 'none' },

            -- 状态栏透明
            StatusLine = { bg = 'none' },
            StatusLineNC = { bg = 'none' },

            -- 让浮动窗口透明
            NormalFloat = { bg = 'none' },
            FloatBorder = { bg = 'none' },
            FloatTitle = { bg = 'none' },

            -- Noice cmdline popup 透明
            NoiceCmdlinePopup = { bg = 'none' },
            NoiceCmdlinePopupBorder = { bg = 'none' },
            NoiceCmdlinePopupTitle = { bg = 'none' },
            NoicePopup = { bg = 'none' },
            NoicePopupBorder = { bg = 'none' },

            -- Fidget (LSP 进度) 透明
            FidgetTitle = { bg = 'none' },
            FidgetTask = { bg = 'none' },

            -- Telescope 透明
            TelescopeNormal = { bg = 'none' },
            TelescopeBorder = { bg = 'none' },
            TelescopePromptNormal = { bg = 'none' },
            TelescopePromptBorder = { bg = 'none' },
            TelescopeResultsNormal = { bg = 'none' },
            TelescopeResultsBorder = { bg = 'none' },
            TelescopePreviewNormal = { bg = 'none' },
            TelescopePreviewBorder = { bg = 'none' },

            -- 补全菜单透明
            Pmenu = { fg = theme.ui.shade0, bg = 'none', blend = 0 },
            PmenuSel = { fg = 'none', bg = theme.ui.bg_p2 },
            PmenuSbar = { bg = 'none' },
            PmenuThumb = { bg = theme.ui.bg_p2 },

            -- 通知透明
            NotifyBackground = { bg = 'none' },

            -- Lazy 弹窗
            LazyNormal = { bg = 'none' },
            LazyBackdrop = { bg = 'none' },

            -- WhichKey 弹窗
            WhichKeyNormal = { bg = 'none' },
            WhichKeyBorder = { bg = 'none', fg = theme.ui.float.fg_border },

            -- Blink.cmp 补全菜单透明
            BlinkCmpMenu = { bg = 'none' },
            BlinkCmpMenuBorder = { bg = 'none' },
            BlinkCmpDoc = { bg = 'none' },
            BlinkCmpDocBorder = { bg = 'none' },
            BlinkCmpSignatureHelp = { bg = 'none' },
            BlinkCmpSignatureHelpBorder = { bg = 'none' },
          }
        end,
      }
      vim.cmd.colorscheme 'kanagawa-dragon'
    end,
  },
}
