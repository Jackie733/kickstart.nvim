return {
  'akinsho/toggleterm.nvim',
  version = '*',
  keys = {
    { '<c-\\>', desc = 'Toggle Terminal' },
    { '<leader>tf', desc = 'ToggleTerm: Bottom Float' },
  },
  cmd = { 'ToggleTerm', 'TermExec' },
  config = function()
    local function set_terminal_options(term)
      vim.bo[term.bufnr].buflisted = false
      vim.wo.number = false
      vim.wo.relativenumber = false
      vim.wo.wrap = false

      local opts = { buffer = term.bufnr, silent = true }
      vim.keymap.set('t', '<C-h>', [[<Cmd>wincmd h<CR>]], vim.tbl_extend('force', opts, { desc = 'Terminal: Navigate Left' }))
      vim.keymap.set('t', '<C-j>', [[<Cmd>wincmd j<CR>]], vim.tbl_extend('force', opts, { desc = 'Terminal: Navigate Down' }))
      vim.keymap.set('t', '<C-k>', [[<Cmd>wincmd k<CR>]], vim.tbl_extend('force', opts, { desc = 'Terminal: Navigate Up' }))
      vim.keymap.set('t', '<C-l>', [[<Cmd>wincmd l<CR>]], vim.tbl_extend('force', opts, { desc = 'Terminal: Navigate Right' }))
    end

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
      open_mapping = [[<c-\>]],
      direction = 'float', -- 默认使用浮动窗口，不会影响 buffer 布局
      on_open = set_terminal_options,
      shade_terminals = false,
      highlights = {
        NormalFloat = { link = 'NormalFloat' },
        FloatBorder = { link = 'FloatBorder' },
      },
      float_opts = {
        border = 'rounded',
        winblend = 0,
        width = function()
          return math.floor(vim.o.columns * 0.9)
        end,
        height = function()
          return math.floor(vim.o.lines * 0.9)
        end,
      },
    }
    local Terminal = require('toggleterm.terminal').Terminal

    local bottom_term = Terminal:new {
      direction = 'float', -- 关键：设置为浮动类型
      hidden = true, -- 方便在后台运行任务
      float_opts = {
        border = 'rounded',
        -- 以下是定位的关键
        width = function()
          return math.floor(vim.o.columns * 0.9)
        end,
        height = function()
          return math.floor(vim.o.lines * 0.4)
        end,
        -- 计算 x, y 坐标使其在底部居中
        col = function()
          return math.floor(vim.o.columns * 0.05)
        end,
        row = function()
          return math.floor(vim.o.lines * 0.6) - 2
        end,
      },
      on_open = set_terminal_options,
    }

    vim.keymap.set('n', '<leader>tf', function()
      bottom_term:toggle()
    end, { silent = true, desc = 'ToggleTerm: Bottom Float' })
  end,
}
