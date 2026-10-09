local parsers = {
  'bash',
  'c',
  'diff',
  'json',
  'jsonc',
  'css',
  'scss',
  'html',
  'jsdoc',
  'lua',
  'luadoc',
  'markdown',
  'markdown_inline',
  'query',
  'regex',
  'typescript',
  'javascript',
  'tsx',
  'rust',
  'sql',
  'toml',
  'vue',
  'python',
  'yaml',
}

return {
  {
    'nvim-treesitter/nvim-treesitter',
    lazy = false,
    build = ':TSUpdate',
    opts = { install_dir = vim.fn.stdpath 'data' .. '/site' },
    config = function(_, opts)
      require('nvim-treesitter').setup(opts)

      -- Installation is explicit, never part of opening a file.
      vim.api.nvim_create_user_command('TSInstallConfigured', function()
        require('nvim-treesitter').install(parsers)
      end, { desc = 'Install the parsers used by TsienVim' })

      vim.api.nvim_create_autocmd('FileType', {
        group = vim.api.nvim_create_augroup('tsien-treesitter', { clear = true }),
        callback = function(event)
          -- Compiling a language's queries can take hundreds of milliseconds.
          -- Let the file draw before doing that work; recheck the buffer afterwards.
          vim.schedule(function()
            if not vim.api.nvim_buf_is_valid(event.buf) or not vim.api.nvim_buf_is_loaded(event.buf) then
              return
            end
            if vim.bo[event.buf].buftype ~= '' or require('core.buffer').is_bigfile(event.buf) then
              return
            end
            local lang = vim.treesitter.language.get_lang(vim.bo[event.buf].filetype)
            if not lang then
              return
            end
            local highlighter = vim.treesitter.highlighter.active[event.buf]
            if highlighter and highlighter.tree:lang() ~= lang then
              vim.treesitter.stop(event.buf)
              highlighter = nil
            end
            if not highlighter then
              local ok, err = pcall(vim.treesitter.start, event.buf, lang)
              if not ok then
                if lang == 'vue' then
                  vim.notify_once('Vue Treesitter could not start. Run :TSInstallConfigured, then restart Neovim.\n' .. tostring(err), vim.log.levels.WARN)
                end
                return -- Missing parsers keep Neovim's normal syntax and indentation.
              end
            end
            if vim.bo[event.buf].filetype == 'ruby' then
              vim.bo[event.buf].syntax = 'ruby'
            else
              local ok, query = pcall(vim.treesitter.query.get, lang, 'indents')
              if ok and query then
                vim.bo[event.buf].indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
              end
            end
          end)
        end,
      })

      -- Capture the native callbacks before mini.ai assigns its own an/in maps.
      local select_parent = vim.fn.maparg('an', 'x', false, true).callback
      local select_child = vim.fn.maparg('in', 'x', false, true).callback
      vim.keymap.set('n', '<C-Space>', function()
        vim.cmd.normal { 'v', bang = true }
        select_parent()
      end, { desc = 'Select syntax node' })
      vim.keymap.set('x', '<C-Space>', select_parent, { desc = 'Expand syntax selection' })
      vim.keymap.set('x', '<BS>', select_child, { desc = 'Shrink syntax selection' })
    end,
  },
  {
    'nvim-treesitter/nvim-treesitter-context',
    event = 'VeryLazy',
    dependencies = { 'nvim-treesitter/nvim-treesitter' },
    opts = {
      enable = true,
      max_lines = 5,
      min_window_height = 5,
      line_numbers = true,
      multiline_threshold = 20,
      trim_scope = 'outer',
      mode = 'cursor',
      zindex = 20,
      on_attach = function(bufnr)
        return not require('core.buffer').is_bigfile(bufnr)
      end,
    },
  },
}
