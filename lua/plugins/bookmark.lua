return {
  {
    'tomasky/bookmarks.nvim',
    event = 'VeryLazy',
    dependencies = {
      'nvim-telescope/telescope.nvim',
    },
    keys = {
      {
        '<leader>km',
        function()
          require('bookmarks').bookmark_toggle()
        end,
        desc = 'Toggle Bookmark',
      },
      {
        '<leader>ka',
        function()
          require('bookmarks').bookmark_ann()
        end,
        desc = 'Annotate Bookmark',
      },
      {
        '<leader>kc',
        function()
          require('bookmarks').bookmark_clean()
        end,
        desc = 'Clean Buffer Bookmarks',
      },
      {
        '<leader>kn',
        function()
          require('bookmarks').bookmark_next()
        end,
        desc = 'Next Bookmark',
      },
      {
        '<leader>kp',
        function()
          require('bookmarks').bookmark_prev()
        end,
        desc = 'Previous Bookmark',
      },
      {
        '<leader>kl',
        function()
          require('bookmarks').bookmark_list()
        end,
        desc = 'List Bookmarks',
      },
    },
    config = function()
      require('bookmarks').setup {
        save_file = vim.fn.expand '$HOME/.bookmarks', -- bookmarks save file path
        keywords = {
          ['@t'] = '☑️ ', -- mark annotation startswith @t ,signs this icon as `Todo`
          ['@w'] = '⚠️ ', -- mark annotation startswith @w ,signs this icon as `Warn`
          ['@f'] = '⛏ ', -- mark annotation startswith @f ,signs this icon as `Fix`
          ['@n'] = ' ', -- mark annotation startswith @n ,signs this icon as `Note`
        },
      }

      require('telescope').load_extension 'bookmarks'
    end,
  },
}
