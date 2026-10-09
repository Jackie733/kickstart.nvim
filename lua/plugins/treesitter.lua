local parsers = require('core.dependencies').parsers

return {
  {
    'nvim-treesitter/nvim-treesitter',
    lazy = false,
    build = ':TSUpdate',
    opts = { install_dir = vim.fn.stdpath 'data' .. '/site' },
    config = function(_, opts)
      require('nvim-treesitter').setup(opts)
      -- JSON's parser supports comments; there is no separate jsonc parser.
      vim.treesitter.language.register('json', 'jsonc')

      -- Explicit bulk installation; missing file parsers are prepared asynchronously.
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
                if vim.tbl_contains(parsers, lang) then
                  -- Never rebuild a parser already loaded into this process.
                  -- ABI/query failures need explicit repair and a restart.
                  if #vim.api.nvim_get_runtime_file('parser/' .. lang .. '.*', true) > 0 then
                    vim.notify_once(
                      'Treesitter could not start for ' .. lang .. '. Run :TsienSetup!, then restart Neovim.\n' .. tostring(err),
                      vim.log.levels.WARN
                    )
                  else
                    require('core.environment').ensure_parser(lang, function(installed)
                      if
                        not installed
                        or not vim.api.nvim_buf_is_valid(event.buf)
                        or not vim.api.nvim_buf_is_loaded(event.buf)
                        or require('core.buffer').is_bigfile(event.buf)
                        or vim.treesitter.language.get_lang(vim.bo[event.buf].filetype) ~= lang
                      then
                        return
                      end
                      local started, problem = pcall(vim.treesitter.start, event.buf, lang)
                      if started then
                        local query_ok, query = pcall(vim.treesitter.query.get, lang, 'indents')
                        if query_ok and query then
                          vim.bo[event.buf].indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
                        end
                      else
                        vim.notify_once(
                          '无法启用 ' .. lang .. ' 高亮：' .. tostring(problem) .. '\n运行 :TsienSetup! 后重启 Neovim。',
                          vim.log.levels.WARN
                        )
                      end
                    end)
                  end
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
