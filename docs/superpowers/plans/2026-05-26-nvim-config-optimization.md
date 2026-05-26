# Neovim Config Optimization Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Modernize and simplify this personal Neovim configuration for frontend, Rust, and Python development while preserving the existing kickstart-style structure.

**Architecture:** Keep the current `lua/core/*` and `lua/plugins/*` layout. Move LSP ownership to explicit Neovim 0.11+ APIs, keep Mason as an installer, and make formatting, linting, DAP, UI, and docs match the approved design.

**Tech Stack:** Neovim `>= 0.11`, `lazy.nvim`, `nvim-lspconfig`, `mason.nvim`, `mason-lspconfig.nvim`, `blink.cmp`, `conform.nvim`, `nvim-lint`, `nvim-dap`, `rustaceanvim`, `snacks.nvim`, `telescope.nvim`.

---

## File Map

- Modify `init.lua`: disable lazy.nvim rocks support to remove irrelevant hererocks health warnings.
- Modify `lua/core/options.lua`: add global floating-window border default.
- Modify `lua/plugins/lsp.lua`: replace deprecated `lspconfig.setup()` flow with `vim.lsp.config()` and explicit `vim.lsp.enable()`.
- Modify `lua/plugins/rust.lua`: make `rustaceanvim` own Rust LSP setup and keep Rust-specific keymaps.
- Modify `lua/plugins/debug.lua`: install and configure Python, JS/TS, and Rust debug adapters without conflicting with rustaceanvim.
- Modify `lua/plugins/conform.lua`: broaden formatter coverage for frontend/data formats.
- Modify `lua/plugins/lint.lua`: remove duplicated Python Ruff linting once Ruff LSP is enabled.
- Modify `lua/plugins/ui.lua`: remove the unused top-level Blink require and enable Snacks `bigfile`/`quickfile`.
- Modify `README.md`: replace stock kickstart README with a concise personal configuration README.
- Do not modify `lua/plugins/copilot.lua`: it is already deleted in the working tree and should remain a user-owned change unless separately requested.

## Task 1: Baseline Snapshot

**Files:**
- Read: repository state only

- [ ] **Step 1: Capture current dirty state**

Run:

```sh
git status --short
```

Expected: shows the pre-existing user changes plus this plan file if it has not been committed yet. Do not stage `lua/plugins/copilot.lua` deletion unless explicitly requested.

- [ ] **Step 2: Verify current config loads before edits**

Run:

```sh
nvim --headless '+lua print("CONFIG_LOAD_OK")' '+qa'
```

Expected output includes:

```text
CONFIG_LOAD_OK
```

## Task 2: Core Lazy And Window Defaults

**Files:**
- Modify: `init.lua`
- Modify: `lua/core/options.lua`

- [ ] **Step 1: Disable unused lazy.nvim rocks support**

In `init.lua`, update only the second argument to `require('lazy').setup` so it includes `rocks = { enabled = false }` before `ui`. Keep the first plugin-spec argument unchanged.

The second argument should have this shape:

```lua
{
  rocks = { enabled = false },
  ui = {
    border = 'rounded',
    icons = vim.g.have_nerd_font and {} or {
      cmd = '⌘',
      config = '🛠',
      event = '📅',
      ft = '📂',
      init = '⚙',
      keys = '🗝',
      plugin = '🔌',
      runtime = '💻',
      require = '🌙',
      source = '📄',
      start = '🚀',
      task = '📌',
      lazy = '💤 ',
    },
  },
}
```

- [ ] **Step 2: Add global rounded floating border**

In `lua/core/options.lua`, add this near the UI-related options after `vim.opt.laststatus = 3`:

```lua
vim.o.winborder = 'rounded'
```

- [ ] **Step 3: Validate core startup**

Run:

```sh
nvim --headless '+lua print(vim.o.winborder)' '+qa'
```

Expected output includes:

```text
rounded
```

- [ ] **Step 4: Commit task changes**

Run:

```sh
git add init.lua lua/core/options.lua
git commit -m "chore: tune lazy and window defaults"
```

Expected: a commit is created containing only `init.lua` and `lua/core/options.lua`.

## Task 3: Modernize LSP Configuration

**Files:**
- Modify: `lua/plugins/lsp.lua`

- [ ] **Step 1: Replace LSP setup with explicit Neovim 0.11+ API**

Replace the contents of `lua/plugins/lsp.lua` with an implementation that keeps the current keymaps and diagnostics, but configures servers through `vim.lsp.config()` and enables only the intended server list.

Use this structure:

```lua
return {
  'neovim/nvim-lspconfig',
  dependencies = {
    { 'mason-org/mason.nvim', opts = {} },
    'mason-org/mason-lspconfig.nvim',
    'WhoIsSethDaniel/mason-tool-installer.nvim',
    'saghen/blink.cmp',
  },
  config = function()
    local function map_lsp(event, keys, func, desc, mode)
      mode = mode or 'n'
      vim.keymap.set(mode, keys, func, { buffer = event.buf, desc = desc })
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
        map_lsp(event, 'K', vim.lsp.buf.hover, 'Hover Documentation')

        local client = vim.lsp.get_client_by_id(event.data.client_id)
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
    local vue_language_server_path = vim.fn.stdpath 'data'
      .. '/mason/packages/vue-language-server/node_modules/@vue/language-server'

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
            client.server_capabilities.semanticTokensProvider = nil
          end
        end,
      },
      vue_ls = {
        before_init = function(_, config)
          local root = config.root_dir or vim.fn.getcwd()
          local project_tsdk = root .. '/node_modules/typescript/lib'
          local fallback_tsdk = vim.fn.stdpath 'data'
            .. '/mason/packages/vtsls/node_modules/@vtsls/language-server/node_modules/typescript/lib'
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
      tailwindcss = {},
      basedpyright = {},
      ruff = {
        init_options = {
          settings = {
            logLevel = 'error',
          },
        },
        on_attach = function(client)
          client.server_capabilities.hoverProvider = false
        end,
      },
    }

    local server_names = { 'lua_ls', 'vtsls', 'vue_ls', 'eslint', 'tailwindcss', 'basedpyright', 'ruff' }
    for _, server_name in ipairs(server_names) do
      local server = servers[server_name]
      server.capabilities = vim.tbl_deep_extend('force', {}, capabilities, server.capabilities or {})
      vim.lsp.config(server_name, server)
    end

    require('mason-lspconfig').setup {
      ensure_installed = server_names,
      automatic_enable = false,
    }

    require('mason-tool-installer').setup {
      ensure_installed = {
        'stylua',
        'prettierd',
        'prettier',
        'ruff',
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
```

- [ ] **Step 2: Verify LSP config loads**

Run:

```sh
nvim --headless '+lua print(vim.inspect(vim.lsp.config.vtsls.filetypes))' '+qa'
```

Expected output includes:

```text
vue
```

- [ ] **Step 3: Verify accidental LSPs are not enabled**

Run:

```sh
nvim --headless '+checkhealth vim.lsp' '+w! /tmp/nvim-lsp-health.txt' '+qa' && rg -n "^- (pyright|rust_analyzer|clangd|stylua):" /tmp/nvim-lsp-health.txt
```

Expected: `rg` exits with no matches. If the shell returns status 1 because no matches were found, that is the expected result.

- [ ] **Step 4: Commit task changes**

Run:

```sh
git add lua/plugins/lsp.lua
git commit -m "refactor: modernize lsp setup"
```

Expected: a commit is created containing only `lua/plugins/lsp.lua`.

## Task 4: Rust And Debug Adapter Ownership

**Files:**
- Modify: `lua/plugins/rust.lua`
- Modify: `lua/plugins/debug.lua`

- [ ] **Step 1: Move rustaceanvim configuration into `init`**

Update `lua/plugins/rust.lua` so `vim.g.rustaceanvim` is set before the plugin initializes:

```lua
return {
  {
    'mrcjkb/rustaceanvim',
    version = '^5',
    lazy = false,
    init = function()
      vim.g.rustaceanvim = {
        tools = {},
        server = {
          on_attach = function(_, bufnr)
            local map = function(keys, func, desc)
              vim.keymap.set('n', keys, func, { buffer = bufnr, desc = 'Rust: ' .. desc })
            end

            map('<leader>ca', function()
              vim.cmd.RustLsp 'codeAction'
            end, 'Code Action')
            map('<leader>dr', function()
              vim.cmd.RustLsp 'debuggables'
            end, 'Debug Runnables')
          end,
          default_settings = {
            ['rust-analyzer'] = {
              cargo = {
                allFeatures = true,
                loadOutDirsFromCheck = true,
                buildScripts = { enable = true },
              },
              checkOnSave = {
                allFeatures = true,
                command = 'clippy',
                extraArgs = { '--no-deps' },
              },
              procMacro = {
                enable = true,
                ignored = {
                  ['async-trait'] = { 'async_trait' },
                  ['napi-derive'] = { 'napi' },
                  ['async-recursion'] = { 'async_recursion' },
                },
              },
            },
          },
        },
        dap = {},
      }
    end,
  },
}
```

- [ ] **Step 2: Update DAP adapter installation list**

In `lua/plugins/debug.lua`, change the `mason-nvim-dap` setup block to install adapter names:

```lua
require('mason-nvim-dap').setup {
  automatic_installation = true,
  handlers = {},
  ensure_installed = {
    'python',
    'js',
    'codelldb',
  },
}
```

- [ ] **Step 3: Add JS/TS DAP adapter and configurations**

After `dapui.setup` in `lua/plugins/debug.lua`, add:

```lua
for _, adapter in ipairs { 'pwa-node', 'pwa-chrome' } do
  dap.adapters[adapter] = {
    type = 'server',
    host = 'localhost',
    port = '${port}',
    executable = {
      command = 'js-debug-adapter',
      args = { '${port}' },
    },
  }
end

dap.adapters.node = function(callback, config)
  config.type = 'pwa-node'
  callback(dap.adapters['pwa-node'])
end

local js_filetypes = { 'javascript', 'javascriptreact', 'typescript', 'typescriptreact', 'vue' }
for _, language in ipairs(js_filetypes) do
  dap.configurations[language] = {
    {
      type = 'pwa-node',
      request = 'launch',
      name = 'Launch file',
      program = '${file}',
      cwd = '${workspaceFolder}',
      sourceMaps = true,
      runtimeExecutable = language:find 'typescript' and (vim.fn.executable 'tsx' == 1 and 'tsx' or 'ts-node') or nil,
      skipFiles = { '<node_internals>/**', 'node_modules/**' },
      resolveSourceMapLocations = { '${workspaceFolder}/**', '!**/node_modules/**' },
    },
    {
      type = 'pwa-node',
      request = 'attach',
      name = 'Attach process',
      processId = require('dap.utils').pick_process,
      cwd = '${workspaceFolder}',
      sourceMaps = true,
      skipFiles = { '<node_internals>/**', 'node_modules/**' },
    },
  }
end
```

- [ ] **Step 4: Validate debug config loads**

Run:

```sh
nvim --headless '+lua require("dap"); print("DAP_LOAD_OK")' '+qa'
```

Expected output includes:

```text
DAP_LOAD_OK
```

- [ ] **Step 5: Commit task changes**

Run:

```sh
git add lua/plugins/rust.lua lua/plugins/debug.lua
git commit -m "feat: align rust and dap setup"
```

Expected: a commit is created containing only `lua/plugins/rust.lua` and `lua/plugins/debug.lua`.

## Task 5: Formatting And Linting Coverage

**Files:**
- Modify: `lua/plugins/conform.lua`
- Modify: `lua/plugins/lint.lua`

- [ ] **Step 1: Expand Conform filetype coverage**

Update `lua/plugins/conform.lua` `opts` to use this formatter map:

```lua
formatters_by_ft = {
  lua = { 'stylua' },
  python = { 'ruff_fix', 'ruff_format', 'ruff_organize_imports' },
  rust = { 'rustfmt' },
  javascript = { 'prettierd', 'prettier', stop_after_first = true },
  typescript = { 'prettierd', 'prettier', stop_after_first = true },
  javascriptreact = { 'prettierd', 'prettier', stop_after_first = true },
  typescriptreact = { 'prettierd', 'prettier', stop_after_first = true },
  vue = { 'prettierd', 'prettier', stop_after_first = true },
  json = { 'prettierd', 'prettier', stop_after_first = true },
  jsonc = { 'prettierd', 'prettier', stop_after_first = true },
  css = { 'prettierd', 'prettier', stop_after_first = true },
  scss = { 'prettierd', 'prettier', stop_after_first = true },
  html = { 'prettierd', 'prettier', stop_after_first = true },
  markdown = { 'prettierd', 'prettier', stop_after_first = true },
  ['markdown.mdx'] = { 'prettierd', 'prettier', stop_after_first = true },
  yaml = { 'prettierd', 'prettier', stop_after_first = true },
  yml = { 'prettierd', 'prettier', stop_after_first = true },
}
```

Keep `format_on_save` but increase timeout to 1000ms:

```lua
format_on_save = {
  timeout_ms = 1000,
  lsp_format = 'fallback',
},
```

- [ ] **Step 2: Remove duplicate Python Ruff linting**

In `lua/plugins/lint.lua`, keep only Markdown linting:

```lua
lint.linters_by_ft = {
  markdown = { 'markdownlint' },
}
```

- [ ] **Step 3: Validate formatter config loads**

Run:

```sh
nvim --headless '+lua local c=require("conform"); print(vim.inspect(c.list_formatters_for_buffer(0)))' '+qa'
```

Expected: command exits successfully. Output may be `{}` because no file buffer is open.

- [ ] **Step 4: Commit task changes**

Run:

```sh
git add lua/plugins/conform.lua lua/plugins/lint.lua
git commit -m "feat: broaden formatting coverage"
```

Expected: a commit is created containing only `lua/plugins/conform.lua` and `lua/plugins/lint.lua`.

## Task 6: UI Performance Cleanup

**Files:**
- Modify: `lua/plugins/ui.lua`

- [ ] **Step 1: Remove unused top-level Blink require**

Delete this line at the top of `lua/plugins/ui.lua`:

```lua
local signature = require 'blink.cmp.config.signature'
```

- [ ] **Step 2: Enable Snacks bigfile and quickfile**

In the `snacks.nvim` plugin opts in `lua/plugins/ui.lua`, insert these two top-level Snacks module options after `words = { enabled = true },`:

```lua
bigfile = { enabled = true },
quickfile = { enabled = true },
```

- [ ] **Step 3: Validate startup no longer eagerly requires Blink signature through UI**

Run:

```sh
nvim --headless --startuptime /tmp/nvim-startup-ui.log '+qa' && rg -n "blink.cmp.config.signature" /tmp/nvim-startup-ui.log
```

Expected: no match for `blink.cmp.config.signature` caused by `lua/plugins/ui.lua`. If `rg` exits 1 because no matches were found, that is acceptable.

- [ ] **Step 4: Commit task changes if `ui.lua` has a diff**

Run:

```sh
git diff -- lua/plugins/ui.lua
git add lua/plugins/ui.lua
git commit -m "perf: tune ui plugin loading"
```

Expected: commit only if `lua/plugins/ui.lua` has an intentional diff after preserving or removing the pre-existing user line according to the approved spec.

## Task 7: README Refresh

**Files:**
- Modify: `README.md`

- [ ] **Step 1: Replace stock kickstart README**

Replace `README.md` with concise project documentation:

```markdown
# TsienVim

Personal Neovim configuration derived from kickstart.nvim and tuned for frontend, Rust, and Python development.

## Requirements

- Neovim `>= 0.11`
- Git
- A C compiler and `make`
- `ripgrep`
- `fd`
- Node.js and npm
- Python 3
- Rust toolchain with `cargo`, `rustfmt`, and `clippy`
- Optional: `lazygit`
- Optional: Nerd Font for richer icons

## Language Support

- React, Vue, TypeScript, JavaScript, and Node.js through `vtsls`, `vue_ls`, `eslint`, `tailwindcss`, `blink.cmp`, and Prettier.
- Rust through `rustaceanvim`, `rust-analyzer`, `clippy`, `rustfmt`, and DAP integration when `codelldb` is available.
- Python through `basedpyright`, `ruff`, `debugpy`, and Conform formatting.
- Markdown, JSON, CSS, SCSS, HTML, and YAML through Treesitter and Prettier-compatible formatting.

## Main Plugin Stack

- Plugin manager: `lazy.nvim`
- Completion: `blink.cmp` with LuaSnip snippets
- LSP: native Neovim 0.11+ `vim.lsp.config()` / `vim.lsp.enable()`
- External tools: `mason.nvim`, `mason-lspconfig.nvim`, `mason-tool-installer.nvim`
- Formatting: `conform.nvim`
- Linting: `nvim-lint`
- Syntax: `nvim-treesitter`
- Search: `telescope.nvim`
- UI: `kanagawa.nvim`, `lualine.nvim`, `bufferline.nvim`, `noice.nvim`, `snacks.nvim`, `neo-tree.nvim`
- Debugging: `nvim-dap`, `nvim-dap-ui`

## Common Commands

```vim
:Lazy
:Mason
:checkhealth
:ConformInfo
:LspInfo
```

## Validation

```sh
nvim --headless '+lua print("CONFIG_LOAD_OK")' '+qa'
nvim --headless '+checkhealth vim.lsp lazy nvim-treesitter mason' '+w! /tmp/nvim-health.txt' '+qa'
nvim --headless --startuptime /tmp/nvim-startup.log '+qa'
```

## Notes

This is a personal configuration, not a distribution. Prefer small explicit plugin specs over large framework abstractions.
```

- [ ] **Step 2: Commit documentation**

Run:

```sh
git add README.md
git commit -m "docs: refresh nvim config readme"
```

Expected: a commit is created containing only `README.md`.

## Task 8: Final Validation

**Files:**
- Read: generated validation output only

- [ ] **Step 1: Verify clean config load**

Run:

```sh
nvim --headless '+lua print("CONFIG_LOAD_OK")' '+qa'
```

Expected output includes:

```text
CONFIG_LOAD_OK
```

- [ ] **Step 2: Run health checks**

Run:

```sh
nvim --headless '+checkhealth vim.lsp lazy nvim-treesitter mason' '+w! /tmp/nvim-health.txt' '+qa'
```

Expected: command exits successfully. Remaining Mason language warnings for uninstalled ecosystems such as Go, Ruby, PHP, Java, or Julia are acceptable because they are not required by this config.

- [ ] **Step 3: Inspect intended LSP enabled list**

Run:

```sh
rg -n "^- (lua_ls|vtsls|vue_ls|eslint|tailwindcss|basedpyright|ruff):" /tmp/nvim-health.txt
rg -n "^- (pyright|rust_analyzer|clangd|stylua):" /tmp/nvim-health.txt
```

Expected: first command finds the intended servers. Second command finds no accidental server entries.

- [ ] **Step 4: Capture startup timing**

Run:

```sh
nvim --headless --startuptime /tmp/nvim-startup.log '+qa' && tail -n 20 /tmp/nvim-startup.log
```

Expected: startup succeeds and the final line includes:

```text
--- NVIM STARTED ---
```

- [ ] **Step 5: Inspect final git state**

Run:

```sh
git status --short
```

Expected: only user-owned pre-existing changes remain if they were not intentionally included. In particular, do not accidentally stage or commit `lua/plugins/copilot.lua` deletion unless the user explicitly asks.
