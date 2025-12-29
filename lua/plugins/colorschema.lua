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
      local function detect_background()
        local sys = (vim.uv or vim.loop).os_uname().sysname

        if sys == 'Darwin' and vim.fn.executable('defaults') == 1 then
          local out = vim.fn.system('defaults read -g AppleInterfaceStyle 2>/dev/null')
          return out:match('Dark') and 'dark' or 'light'
        end

        if sys == 'Linux' and vim.fn.executable('gsettings') == 1 then
          local out = vim.fn.system("gsettings get org.gnome.desktop.interface color-scheme 2>/dev/null")
          if out:match('prefer%-dark') then
            return 'dark'
          elseif out:match('default') then
            return 'light'
          end
        end

        if sys == 'Linux' and vim.fn.executable('kreadconfig5') == 1 then
          local out = vim.fn.system("kreadconfig5 --file kdeglobals --group General --key ColorScheme 2>/dev/null")
          if out:lower():match('dark') then
            return 'dark'
          elseif out:match('%S') then
            return 'light'
          end
        end

        return nil
      end

      local function apply_background(bg)
        local scheme = (bg == 'light') and 'kanagawa-lotus' or 'kanagawa-wave'
        vim.o.background = bg
        if vim.g.colors_name ~= scheme then
          pcall(vim.cmd.colorscheme, scheme)
        end
      end

      local last = nil
      local function refresh()
        local bg = detect_background() or vim.o.background
        if bg ~= last then
          last = bg
          apply_background(bg)
        end
      end

      refresh()

      vim.api.nvim_create_autocmd({ 'VimEnter', 'FocusGained' }, {
        group = vim.api.nvim_create_augroup('TsienVimAutoTheme', { clear = true }),
        callback = function()
          pcall(refresh)
        end,
      })

      if not vim.g.__tsien_auto_theme_timer_started then
        vim.g.__tsien_auto_theme_timer_started = true
        local timer = (vim.uv or vim.loop).new_timer()
        timer:start(0, 3000, vim.schedule_wrap(function()
          pcall(refresh)
        end))
        vim.api.nvim_create_autocmd('VimLeavePre', {
          group = vim.api.nvim_create_augroup('TsienVimAutoThemeStop', { clear = true }),
          callback = function()
            pcall(function()
              timer:stop()
              timer:close()
            end)
          end,
        })
      end
    end,
  },
}
