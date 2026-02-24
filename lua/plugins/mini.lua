return {
  {
    'echasnovski/mini.nvim',
    event = 'VeryLazy',
    dependencies = {
      'JoosepAlviste/nvim-ts-context-commentstring',
    },
    config = function()
      -- Better Around/Inside textobjects
      require('mini.ai').setup { n_lines = 500 }

      -- Add/delete/replace surroundings (brackets, quotes, etc.)
      -- 使用 gz 前缀避免与 flash.nvim 的 s 键冲突
      require('mini.surround').setup {
        mappings = {
          add = 'gza', -- Add surrounding in Normal and Visual modes
          delete = 'gzd', -- Delete surrounding
          find = 'gzf', -- Find surrounding (to the right)
          find_left = 'gzF', -- Find surrounding (to the left)
          highlight = 'gzh', -- Highlight surrounding
          replace = 'gzr', -- Replace surrounding
          update_n_lines = 'gzn', -- Update `n_lines`
        },
      }

      -- Auto pairs
      require('mini.pairs').setup()

      -- Simple and easy comment: gcc, gc{motion}, gc (visual)
      require('mini.comment').setup {
        options = {
          custom_commentstring = function()
            local cs = require('ts_context_commentstring.internal').calculate_commentstring()
            if cs and cs ~= '' then
              return cs
            end
            -- Fallback to buffer's commentstring or default
            local bo_cs = vim.bo.commentstring
            if bo_cs and bo_cs ~= '' then
              return bo_cs
            end
            return '// %s'
          end,
        },
      }
    end,
  },
}
