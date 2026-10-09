return {
  'neovim/nvim-lspconfig',
  event = { 'BufReadPre', 'BufNewFile' },
  cmd = { 'MasonToolsInstall', 'MasonToolsUpdate', 'MasonToolsClean' },
  dependencies = {
    { 'mason-org/mason.nvim', opts = {} },
    'mason-org/mason-lspconfig.nvim',
    'WhoIsSethDaniel/mason-tool-installer.nvim',
    'b0o/SchemaStore.nvim',
  },
  config = function()
    local project = require 'core.project'

    local function map_lsp(event, keys, func, desc, mode)
      mode = mode or 'n'
      vim.keymap.set(mode, keys, func, { buffer = event.buf, desc = desc })
    end

    local function root_dir(root_fn, fallback_to_cwd)
      return function(bufnr, on_dir)
        local root = root_fn(bufnr)
        if root then
          on_dir(root)
        elseif fallback_to_cwd then
          on_dir(vim.fn.getcwd())
        end
      end
    end

    local function telescope_lsp(picker)
      return function()
        require('telescope.builtin')[picker]()
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
        command = 'typescript.goToSourceDefinition',
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
      return client:supports_method(method, bufnr)
    end

    local function disable_formatting(client)
      client.server_capabilities.documentFormattingProvider = false
      client.server_capabilities.documentRangeFormattingProvider = false
    end

    vim.api.nvim_create_autocmd('LspAttach', {
      group = vim.api.nvim_create_augroup('tsien-lsp-attach', { clear = true }),
      callback = function(event)
        map_lsp(event, '<leader>cr', vim.lsp.buf.rename, '[C]ode [R]ename')
        map_lsp(event, '<leader>ca', vim.lsp.buf.code_action, '[C]ode [A]ction', { 'n', 'x' })
        map_lsp(event, 'gD', vim.lsp.buf.declaration, '[G]oto [D]eclaration')
        map_lsp(event, 'gd', telescope_lsp 'lsp_definitions', '[G]oto [d]efinition')
        map_lsp(event, 'gr', telescope_lsp 'lsp_references', '[G]oto [R]eferences')
        map_lsp(event, 'gI', telescope_lsp 'lsp_implementations', '[G]oto [I]mplementation')
        map_lsp(event, 'gy', telescope_lsp 'lsp_type_definitions', '[G]oto T[y]pe Definition')
        map_lsp(event, '<leader>cs', telescope_lsp 'lsp_document_symbols', '[C]ode [S]ymbols')
        map_lsp(event, '<leader>cS', telescope_lsp 'lsp_dynamic_workspace_symbols', '[C]ode Workspace [S]ymbols')
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

    local capabilities = vim.lsp.protocol.make_client_capabilities()
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
          if vim.bo[bufnr].filetype == 'vue' then
            -- Neovim 0.12 accepts a buffer or a client filter, never both.
            -- Treesitter owns Vue colors; retain semantic tokens in TS/JS buffers.
            vim.lsp.semantic_tokens.enable(false, { bufnr = bufnr })
          end
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
        root_dir = root_dir(project.eslint_root),
        settings = {
          workingDirectory = { mode = 'auto' },
          format = false,
        },
      },
      oxlint = {
        root_dir = root_dir(project.oxlint_root),
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
        root_dir = root_dir(project.python_root, true),
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
        root_dir = root_dir(project.python_root, true),
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
        end, true),
        on_attach = disable_formatting,
      },
    }

    local dependencies = require 'core.dependencies'
    local server_names = vim.tbl_keys(dependencies.servers)
    table.sort(server_names)
    local has_external_sqls = vim.fn.executable 'sqls' == 1
    if has_external_sqls or vim.fn.executable 'go' == 1 then
      table.insert(server_names, 'sqls')
    end
    for _, server_name in ipairs(server_names) do
      local server = servers[server_name]
      server.capabilities = vim.tbl_deep_extend('force', {}, capabilities, server.capabilities or {})
      vim.lsp.config(server_name, server)
    end

    local mason_server_names = vim.tbl_filter(function(server_name)
      -- Mason builds sqls from source and requires Go; keep an existing binary external.
      return server_name ~= 'sqls' or not has_external_sqls
    end, server_names)

    require('mason-lspconfig').setup {
      ensure_installed = mason_server_names,
      automatic_enable = false,
    }

    require('mason-tool-installer').setup {
      run_on_start = false,
      ensure_installed = dependencies.tools,
      integrations = {
        ['mason-lspconfig'] = false,
        ['mason-null-ls'] = false,
        ['mason-nvim-dap'] = false,
      },
    }

    vim.lsp.enable(server_names)
    vim.api.nvim_set_hl(0, '@lsp.type.component.vue', { link = '@type' })
  end,
}
