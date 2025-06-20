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
