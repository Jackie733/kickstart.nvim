return {
  'nvim-neo-tree/neo-tree.nvim',
  branch = 'v3.x',
  dependencies = {
    'nvim-lua/plenary.nvim',
    'nvim-tree/nvim-web-devicons',
    'MunifTanjim/nui.nvim',
  },
  cmd = 'Neotree',
  keys = {
    { '<leader>e', '<cmd>Neotree toggle<cr>', desc = 'Explorer NeoTree (root dir)' },
    { '<leader>E', '<cmd>Neotree toggle float<cr>', desc = 'Explorer NeoTree (float)' },
    { '<leader>ge', '<cmd>Neotree float git_status<cr>', desc = 'Git explorer' },
    { '<leader>be', '<cmd>Neotree toggle show buffers right<cr>', desc = 'Buffer explorer' },
  },
  deactivate = function()
    vim.cmd [[Neotree close]]
  end,
  opts = {
    sources = { 'filesystem', 'buffers', 'git_status', 'document_symbols' },
    open_files_do_not_replace_types = { 'terminal', 'Trouble', 'trouble', 'qf', 'Outline' },
    -- 新增/重命名文件后自动定位
    event_handlers = {
      {
        event = 'file_added',
        handler = function(file_path)
          vim.schedule(function()
            require('neo-tree.command').execute { action = 'show', reveal_file = file_path }
          end)
        end,
      },
      {
        event = 'file_renamed',
        handler = function(args)
          vim.schedule(function()
            require('neo-tree.command').execute { action = 'show', reveal_file = args.destination }
          end)
        end,
      },
    },
    filesystem = {
      bind_to_cwd = false,
      follow_current_file = { enabled = true },
      use_libuv_file_watcher = true,
      filtered_items = {
        visible = false,
        hide_dotfiles = false,
        hide_gitignored = true,
        hide_hidden = true,
        hide_by_name = {
          'node_modules',
          '.git',
          '.DS_Store',
          'thumbs.db',
        },
        never_show = {
          '.DS_Store',
          'thumbs.db',
        },
      },
    },
    window = {
      mappings = {
        ['<space>'] = 'none',
        ['Y'] = {
          function(state)
            local node = state.tree:get_node()
            local path = node:get_id()
            vim.fn.setreg('+', path, 'c')
          end,
          desc = 'copy path to clipboard',
        },
        ['O'] = {
          function(state)
            require('lazy.util').open(state.tree:get_node().path, { system = true })
          end,
          desc = 'open with system application',
        },
        ['P'] = { 'toggle_preview', config = { use_float = false } },
      },
    },
    default_component_configs = {
      indent = {
        with_expanders = true, -- if nil and file nesting is enabled, will enable expanders
        expander_collapsed = '',
        expander_expanded = '',
        expander_highlight = 'NeoTreeExpander',
      },
      git_status = {
        symbols = {
          unstaged = '󰄱',
          staged = '󰱒',
        },
      },
    },
  },
  config = function(_, opts)
    require('neo-tree').setup(opts)
    vim.api.nvim_create_autocmd('TermClose', {
      pattern = '*lazygit',
      callback = function()
        if package.loaded['neo-tree.sources.git_status'] then
          require('neo-tree.sources.git_status').refresh()
        end
      end,
    })
  end,
}
