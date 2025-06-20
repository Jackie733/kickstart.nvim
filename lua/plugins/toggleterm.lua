return {
  'akinsho/toggleterm.nvim',
  version = '*',
  config = function()
    require('toggleterm').setup {
      -- 大小可以是一个数字（表示行数/列数），也可以是一个0-1之间的小数（表示占屏幕的比例）
      size = function(term)
        if term.direction == 'horizontal' then
          return 15 -- 水平分割的终端高度为 15 行
        elseif term.direction == 'vertical' then
          return vim.o.columns * 0.4 -- 垂直分割的终端占屏幕宽度的 40%
        end
        -- 浮动终端的大小，可以自行调整
        return 120
      end,
      -- 注意：<C-t> 会立即加载插件，如果你希望完全延迟加载，可以移除这个映射
      -- 然后在上面的 `keys` 表中添加一个 <C-t> 的映射
      open_mapping = [[<c-\>]],
      shading_factor = 2,
      float_opts = {
        border = 'rounded',
        winblend = 0,
        highlights = {
          border = 'FloatBorder',
          background = 'Normal',
        },
      },
    }
    local Terminal = require('toggleterm.terminal').Terminal

    -- 计算窗口尺寸和位置
    local term_width = math.floor(vim.o.columns * 0.9)
    local term_height = math.floor(vim.o.lines * 0.4)

    local bottom_term = Terminal:new {
      direction = 'float', -- 关键：设置为浮动类型
      hidden = true, -- 方便在后台运行任务
      float_opts = {
        border = 'rounded',
        -- 以下是定位的关键
        width = term_width,
        height = term_height,
        -- 计算 x, y 坐标使其在底部居中
        col = math.floor((vim.o.columns - term_width) / 2),
        row = math.floor(vim.o.lines - term_height - 2), -- -2 是为了离底部边缘有一点距离
      },
      on_open = function(term)
        -- 进入终端时禁用自动换行，保持排版整洁
        vim.cmd 'setlocal nonumber norelativenumber nowrap'
      end,
    }

    function _G.bottom_term_toggle()
      bottom_term:toggle()
    end

    -- 为这个新的底部终端设置一个专属快捷键，例如 <leader>tb (t for terminal, b for bottom)
    vim.api.nvim_set_keymap('n', '<leader>tf', '<cmd>lua bottom_term_toggle()<cr>', { noremap = true, silent = true, desc = 'ToggleTerm: Bottom Float' })

    -- --- 终端模式下的快捷键 ---
    -- 这些快捷键只在终端 buffer 中生效，所以放在 config 里是合适的
    vim.keymap.set('t', '<esc>', [[<C-\><C-n>]], { noremap = true, silent = true, desc = 'Exit terminal mode' })
    vim.keymap.set('t', '<C-[>', [[<C-\><C-n>]], { noremap = true, silent = true, desc = 'Exit terminal mode' })
    vim.keymap.set('t', '<C-h>', [[<Cmd>wincmd h<CR>]], { noremap = true, silent = true, desc = 'Terminal: Navigate Left' })
    vim.keymap.set('t', '<C-j>', [[<Cmd>wincmd j<CR>]], { noremap = true, silent = true, desc = 'Terminal: Navigate Down' })
    vim.keymap.set('t', '<C-k>', [[<Cmd>wincmd k<CR>]], { noremap = true, silent = true, desc = 'Terminal: Navigate Up' })
    vim.keymap.set('t', '<C-l>', [[<Cmd>wincmd l<CR>]], { noremap = true, silent = true, desc = 'Terminal: Navigate Right' })
  end,
}
