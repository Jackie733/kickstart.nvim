return {
  'neovim/nvim-lspconfig',
  event = { 'BufReadPre', 'BufNewFile' },
  dependencies = {
    { 'mason-org/mason.nvim', opts = {} },
    'mason-org/mason-lspconfig.nvim',
    'WhoIsSethDaniel/mason-tool-installer.nvim',
    'b0o/SchemaStore.nvim',
    'saghen/blink.cmp',
  },
  config = function()
    local project = require 'core.project'

    local function map_lsp(event, keys, func, desc, mode)
      mode = mode or 'n'
      vim.keymap.set(mode, keys, func, { buffer = event.buf, desc = desc })
    end

    local function root_dir(root_fn)
      return function(bufnr, on_dir)
        local root = root_fn(bufnr)
        if root then
          on_dir(root)
        else
          on_dir(vim.fn.getcwd())
        end
      end
    end

    local function ts_source_action(kinds)
      kinds = type(kinds) == 'table' and kinds or { kinds }
      vim.lsp.buf.code_action {
        apply = true,
        context = {
          only = kinds,
          diagnostics = {},
        },
      }
    end

    local function ts_go_to_source_definition(client, bufnr)
      local params = vim.lsp.util.make_position_params(vim.api.nvim_get_current_win(), client.offset_encoding)
      client:exec_cmd({
        command = '_typescript.goToSourceDefinition',
        title = 'Go to source definition',
        arguments = { params.textDocument.uri, params.position },
      }, { bufnr = bufnr }, function(err, result)
        if err then
          vim.notify('Go to source definition failed: ' .. err.message, vim.log.levels.ERROR)
          return
        end
        if not result or vim.tbl_isempty(result) then
          vim.notify('No source definition found', vim.log.levels.INFO)
          return
        end
        vim.lsp.util.show_document(result[1], client.offset_encoding, { focus = true })
      end)
    end

    local function client_supports_method(client, method, bufnr)
      if vim.fn.has 'nvim-0.11' == 1 then
        return client:supports_method(method, bufnr)
      end
      return client.supports_method(method, { bufnr = bufnr })
    end

    local function disable_formatting(client)
      client.server_capabilities.documentFormattingProvider = false
      client.server_capabilities.documentRangeFormattingProvider = false
    end

    local semantic_tokens_full_by_client = {}
    local function set_full_semantic_tokens(client, enabled)
      local semantic_tokens = client.server_capabilities.semanticTokensProvider
      if not semantic_tokens then
        return
      end

      if semantic_tokens_full_by_client[client.id] == nil then
        semantic_tokens_full_by_client[client.id] = semantic_tokens.full
      end

      semantic_tokens.full = enabled and semantic_tokens_full_by_client[client.id] or false
    end

    vim.api.nvim_create_autocmd('LspAttach', {
      group = vim.api.nvim_create_augroup('tsien-lsp-attach', { clear = true }),
      callback = function(event)
        map_lsp(event, '<leader>cr', vim.lsp.buf.rename, '[C]ode [R]ename')
        map_lsp(event, '<leader>ca', vim.lsp.buf.code_action, '[C]ode [A]ction', { 'n', 'x' })
        map_lsp(event, 'gD', vim.lsp.buf.declaration, '[G]oto [D]eclaration')
        map_lsp(event, 'gd', require('telescope.builtin').lsp_definitions, '[G]oto [d]efinition')
        map_lsp(event, 'gr', require('telescope.builtin').lsp_references, '[G]oto [R]eferences')
        map_lsp(event, 'gI', require('telescope.builtin').lsp_implementations, '[G]oto [I]mplementation')
        map_lsp(event, 'gy', require('telescope.builtin').lsp_type_definitions, '[G]oto T[y]pe Definition')
        map_lsp(event, '<leader>cs', require('telescope.builtin').lsp_document_symbols, '[C]ode [S]ymbols')
        map_lsp(event, '<leader>cS', require('telescope.builtin').lsp_dynamic_workspace_symbols, '[C]ode Workspace [S]ymbols')
        map_lsp(event, 'K', function()
          vim.lsp.buf.hover()
        end, 'Hover Documentation')

        local client = vim.lsp.get_client_by_id(event.data.client_id)
        if client and client.name == 'vtsls' then
          map_lsp(event, '<leader>co', function()
            ts_source_action { 'source.organizeImports', 'source.organizeImports.ts' }
          end, '[C]ode [O]rganize Imports')
          map_lsp(event, '<leader>cU', function()
            ts_source_action { 'source.removeUnused', 'source.removeUnused.ts' }
          end, '[C]ode Remove [U]nused')
          map_lsp(event, '<leader>cF', function()
            ts_source_action { 'source.fixAll', 'source.fixAll.ts' }
          end, '[C]ode [F]ix All')
          map_lsp(event, 'gS', function()
            ts_go_to_source_definition(client, event.buf)
          end, '[G]oto [S]ource Definition')
        end

        if client and client_supports_method(client, vim.lsp.protocol.Methods.textDocument_documentHighlight, event.buf) then
          local highlight_group = vim.api.nvim_create_augroup('tsien-lsp-highlight', { clear = false })
          vim.api.nvim_create_autocmd({ 'CursorHold', 'CursorHoldI' }, {
            buffer = event.buf,
            group = highlight_group,
            callback = vim.lsp.buf.document_highlight,
          })
          vim.api.nvim_create_autocmd({ 'CursorMoved', 'CursorMovedI' }, {
            buffer = event.buf,
            group = highlight_group,
            callback = vim.lsp.buf.clear_references,
          })
          vim.api.nvim_create_autocmd('LspDetach', {
            group = vim.api.nvim_create_augroup('tsien-lsp-detach', { clear = true }),
            callback = function(detach_event)
              vim.lsp.buf.clear_references()
              vim.api.nvim_clear_autocmds { group = 'tsien-lsp-highlight', buffer = detach_event.buf }
            end,
          })
        end

        if client and client_supports_method(client, vim.lsp.protocol.Methods.textDocument_inlayHint, event.buf) then
          map_lsp(event, '<leader>th', function()
            vim.lsp.inlay_hint.enable(not vim.lsp.inlay_hint.is_enabled { bufnr = event.buf })
          end, '[T]oggle Inlay [H]ints')
        end
      end,
    })

    vim.diagnostic.config {
      severity_sort = true,
      float = { border = 'rounded', source = 'if_many' },
      underline = { severity = vim.diagnostic.severity.ERROR },
      signs = vim.g.have_nerd_font and {
        text = {
          [vim.diagnostic.severity.ERROR] = TsienVim.icons.diagnostics.Error,
          [vim.diagnostic.severity.WARN] = TsienVim.icons.diagnostics.Warn,
          [vim.diagnostic.severity.INFO] = TsienVim.icons.diagnostics.Info,
          [vim.diagnostic.severity.HINT] = TsienVim.icons.diagnostics.Hint,
        },
      } or {},
      virtual_text = {
        source = 'if_many',
        spacing = 2,
      },
    }

    local capabilities = require('blink.cmp').get_lsp_capabilities()
    local vue_language_server_path = vim.fn.stdpath 'data' .. '/mason/packages/vue-language-server/node_modules/@vue/language-server'

    local ts_inlay_hints = {
      enumMemberValues = { enabled = true },
      functionLikeReturnTypes = { enabled = true },
      parameterNames = { enabled = 'literals' },
      parameterTypes = { enabled = true },
      propertyDeclarationTypes = { enabled = true },
      variableTypes = { enabled = false },
    }

    local servers = {
      lua_ls = {
        settings = {
          Lua = {
            completion = { callSnippet = 'Replace' },
          },
        },
      },
      vtsls = {
        filetypes = { 'javascript', 'javascriptreact', 'typescript', 'typescriptreact', 'vue' },
        settings = {
          complete_function_calls = true,
          vtsls = {
            autoUseWorkspaceTsdk = true,
            enableMoveToFileCodeAction = true,
            experimental = {
              maxInlayHintLength = 30,
              completion = { enableServerSideFuzzyMatch = true },
            },
            tsserver = {
              globalPlugins = {
                {
                  name = '@vue/typescript-plugin',
                  location = vue_language_server_path,
                  languages = { 'vue' },
                  configNamespace = 'typescript',
                  enableForWorkspaceTypeScriptVersions = true,
                },
              },
            },
          },
          typescript = {
            updateImportsOnFileMove = { enabled = 'always' },
            suggest = { completeFunctionCalls = true },
            inlayHints = ts_inlay_hints,
          },
          javascript = {
            updateImportsOnFileMove = { enabled = 'always' },
            suggest = { completeFunctionCalls = true },
            inlayHints = ts_inlay_hints,
          },
        },
        on_attach = function(client, bufnr)
          disable_formatting(client)
          set_full_semantic_tokens(client, vim.bo[bufnr].filetype ~= 'vue')
        end,
      },
      vue_ls = {
        before_init = function(_, config)
          local root = type(config.root_dir) == 'string' and config.root_dir or vim.fn.getcwd()
          local project_tsdk = root .. '/node_modules/typescript/lib'
          local fallback_tsdk = vim.fn.stdpath 'data' .. '/mason/packages/vtsls/node_modules/@vtsls/language-server/node_modules/typescript/lib'

          config.init_options = config.init_options or {}
          config.init_options.typescript = {
            tsdk = vim.fn.isdirectory(project_tsdk) == 1 and project_tsdk or fallback_tsdk,
          }
        end,
        on_attach = disable_formatting,
      },
      eslint = {
        settings = {
          workingDirectory = { mode = 'auto' },
          format = false,
        },
      },
      tailwindcss = {
        filetypes = {
          'html',
          'css',
          'scss',
          'javascript',
          'javascriptreact',
          'typescript',
          'typescriptreact',
          'vue',
        },
        settings = {
          tailwindCSS = {
            includeLanguages = {
              html = 'html',
              javascript = 'javascript',
              javascriptreact = 'javascriptreact',
              typescript = 'typescript',
              typescriptreact = 'typescriptreact',
              vue = 'html',
            },
            experimental = {
              classRegex = {
                { [[(?:cn|clsx|classNames|twMerge)\(([^)]*)\)]], [["'`]([^"'`]*).*?["'`]] },
                { [[cva\(([^)]*)\)]], [["'`]([^"'`]*).*?["'`]] },
                { [[tv\(([^)]*)\)]], [["'`]([^"'`]*).*?["'`]] },
              },
            },
          },
        },
      },
      html = {},
      cssls = {},
      jsonls = {
        settings = {
          json = {
            schemas = require('schemastore').json.schemas(),
            validate = { enable = true },
          },
        },
      },
      yamlls = {
        settings = {
          yaml = {
            schemaStore = { enable = false, url = '' },
            schemas = require('schemastore').yaml.schemas(),
            validate = true,
            keyOrdering = false,
          },
        },
      },
      basedpyright = {
        root_dir = root_dir(project.python_root),
        settings = {
          basedpyright = {
            disableOrganizeImports = true,
            analysis = {
              autoImportCompletions = true,
              diagnosticSeverityOverrides = {
                reportUnusedImport = 'none',
                reportUnusedVariable = 'none',
              },
            },
          },
        },
        before_init = function(_, config)
          local root = type(config.root_dir) == 'string' and config.root_dir or vim.fn.getcwd()
          config.settings = config.settings or {}
          config.settings.python = vim.tbl_deep_extend('force', config.settings.python or {}, {
            pythonPath = project.python_path_for_root(root),
          })
        end,
      },
      ruff = {
        root_dir = root_dir(project.python_root),
        init_options = {
          settings = {
            logLevel = 'error',
          },
        },
        on_attach = function(client)
          client.server_capabilities.hoverProvider = false
        end,
      },
      sqruff = {},
      sqls = {
        root_dir = root_dir(function(bufnr)
          return vim.fs.root(bufnr, { '.sqruff', '.git' })
        end),
        on_attach = disable_formatting,
      },
    }

    local server_names = {
      'lua_ls',
      'vtsls',
      'vue_ls',
      'eslint',
      'tailwindcss',
      'html',
      'cssls',
      'jsonls',
      'yamlls',
      'basedpyright',
      'ruff',
      'sqruff',
      'sqls',
    }
    for _, server_name in ipairs(server_names) do
      local server = servers[server_name]
      server.capabilities = vim.tbl_deep_extend('force', {}, capabilities, server.capabilities or {})
      vim.lsp.config(server_name, server)
    end

    local mason_server_names = vim.tbl_filter(function(server_name)
      -- Mason builds sqls from source and requires Go; use an existing binary when available.
      return server_name ~= 'sqls' or vim.fn.executable 'sqls' == 0
    end, server_names)

    require('mason-lspconfig').setup {
      ensure_installed = mason_server_names,
      automatic_enable = false,
    }

    require('mason-tool-installer').setup {
      ensure_installed = {
        'stylua',
        'prettierd',
        'prettier',
        'ruff',
        'shfmt',
        'html-lsp',
        'css-lsp',
        'json-lsp',
        'yaml-language-server',
        'markdownlint',
        'debugpy',
        'js-debug-adapter',
        'codelldb',
      },
    }

    vim.lsp.enable(server_names)
    vim.api.nvim_set_hl(0, '@lsp.type.component.vue', { link = '@type' })
  end,
}
