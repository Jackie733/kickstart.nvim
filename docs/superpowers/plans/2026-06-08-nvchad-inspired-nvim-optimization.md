# NvChad-Inspired Neovim Optimization Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Improve this personal Neovim config by borrowing NvChad's UI discipline while fixing current keymap conflicts, reducing startup work, and strengthening frontend, Rust, and Python development support.

**Architecture:** Keep the existing kickstart-style `lua/core/*` and `lua/plugins/*` structure. Do not migrate to NvChad. Borrow the useful ideas: centralized theme highlights, compact statusline/dashboard, lazy UI loading, color previews, clear keymap groups, and polished picker/file UI.

**Tech Stack:** Neovim 0.11+, lazy.nvim, Kanagawa, Snacks, Lualine, Bufferline, Telescope, Neo-tree, blink.cmp, nvim-lspconfig, mason.nvim, conform.nvim, nvim-lint, rustaceanvim, nvim-dap.

---

## File Structure

- Modify `init.lua`: lazy.nvim runtime performance options.
- Modify `lua/core/options.lua`: Nerd Font flag and provider policy if needed.
- Create `lua/core/theme.lua`: one place for transparent Kanagawa and plugin highlight overrides.
- Modify `lua/plugins/colorschema.lua`: call `core.theme` instead of owning large override tables.
- Modify `lua/plugins/telescope.lua`: NvChad-style picker layout and preserved search keymaps.
- Modify `lua/plugins/grug-far.lua`: move replace keymaps away from `<leader>s*`.
- Modify `lua/plugins/gitsigns.lua`: remove or correct the bogus current-line Git info mapping.
- Modify `lua/plugins/which-key.lua`: add stable Replace and Diagnostics/List groups.
- Modify `lua/plugins/lsp.lua`: add HTML, CSS, JSON, YAML, and SchemaStore support; lazy-load on file events.
- Modify `lua/plugins/autocompletion.lua`: lazy-load on `InsertEnter`; add buffer source with low priority.
- Modify `lua/plugins/treesitter.lua`: lazy-load on file events; add frontend/data parsers.
- Create `lua/plugins/frontend.lua`: autotag and color preview plugins.
- Modify `lua/plugins/conform.lua`: improve Python order and `gq` formatting integration.
- Create `lua/plugins/trouble.lua`: diagnostics, references, symbols, quickfix, and loclist UI.
- Modify `lua/plugins/ui.lua`: NvChad-inspired dashboard, lualine, bufferline, and Snacks toggles.
- Modify `lua/plugins/debug.lua`: add browser debugging configs for React/Vue apps.
- Modify `README.md`: document the optimized stack, key choices, and validation commands.

## Task 1: Baseline Snapshot

**Files:**
- Read only

- [x] **Step 1: Capture repository state**

Run:

```sh
git status --short
```

Expected: no unrelated changes are modified by this plan. If unrelated user changes exist, leave them alone.

- [x] **Step 2: Capture current plugin startup stats**

Run:

```sh
nvim --headless '+lua print(vim.inspect(require("lazy").stats()))' '+qa'
```

Expected: config loads and prints a table. Current observed baseline was 43 plugins, 15 loaded at startup, and `LazyDone` around 113 ms.

- [x] **Step 3: Capture current startup timing**

Run:

```sh
nvim --headless --startuptime /tmp/tsien-nvim-startup-before.log '+qa'
tail -n 80 /tmp/tsien-nvim-startup-before.log
```

Expected: startup completes. Keep the log for comparison after performance changes.

- [x] **Step 4: Capture current health**

Run:

```sh
nvim --headless '+checkhealth vim.lsp lazy nvim-treesitter mason' '+w! /tmp/tsien-nvim-health-before.txt' '+qa'
rg -n "ERROR|WARN|WARNING|FAILED|not found|missing|deprecated" /tmp/tsien-nvim-health-before.txt
```

Expected: no lazy.nvim, nvim-treesitter, or vim.lsp errors. Mason may warn for non-target languages such as Go, Ruby, PHP, Java, or Julia.

## Task 2: Fix Keymap Correctness

**Files:**
- Modify `lua/plugins/grug-far.lua`
- Modify `lua/plugins/gitsigns.lua`
- Modify `lua/plugins/which-key.lua`

- [x] **Step 1: Confirm current conflicts**

Run:

```sh
rg -n "<leader>s[rwf]|<leader>gl" lua/core lua/plugins
```

Expected: conflicts appear between Telescope and Grug Far for `<leader>sr`, `<leader>sw`, and `<leader>sf`; `gitsigns.lua` contains a misleading `<leader>gl` mapping.

- [x] **Step 2: Move replace keymaps to `<leader>r`**

In `lua/plugins/grug-far.lua`, use these mappings:

```lua
keys = {
  {
    '<leader>rr',
    function()
      require('grug-far').open()
    end,
    desc = '[R]eplace in project',
  },
  {
    '<leader>rw',
    function()
      require('grug-far').open { prefills = { search = vim.fn.expand '<cword>' } }
    end,
    desc = '[R]eplace current [W]ord',
  },
  {
    '<leader>rf',
    function()
      require('grug-far').open { prefills = { paths = vim.fn.expand '%' } }
    end,
    mode = { 'n', 'v' },
    desc = '[R]eplace in current [F]ile',
  },
}
```

- [x] **Step 3: Keep Telescope search keys unchanged**

Do not change `lua/plugins/telescope.lua` search mappings:

```lua
{ '<leader>sf', '<cmd>Telescope find_files<cr>', desc = '[S]earch [F]iles' },
{ '<leader>sw', '<cmd>Telescope grep_string<cr>', desc = '[S]earch current [W]ord' },
{ '<leader>sr', '<cmd>Telescope resume<cr>', desc = '[S]earch [R]esume' },
```

- [x] **Step 4: Fix Git blame behavior**

In `lua/plugins/gitsigns.lua`, remove the `<leader>gl` block that prints `gitsigns.get_hunks()[1]`.

Change the existing `<leader>hb` mapping to full blame:

```lua
map('n', '<leader>hb', function()
  gitsigns.blame_line { full = true }
end, { desc = 'git [b]lame line' })
```

- [x] **Step 5: Add Replace group to which-key**

In `lua/plugins/which-key.lua`, add:

```lua
{ '<leader>r', group = '[R]eplace' },
```

- [x] **Step 6: Validate keymap conflicts are gone**

Run:

```sh
rg -n "<leader>s[rwf]|<leader>r[rwf]|<leader>gl" lua/core lua/plugins
nvim --headless '+lua print("CONFIG_LOAD_OK")' '+qa'
```

Expected: `<leader>s*` belongs to Telescope, `<leader>r*` belongs to Grug Far, no `<leader>gl` mapping remains, and config loads.

## Task 3: Reduce Startup Work

**Files:**
- Modify `init.lua`
- Modify `lua/plugins/lsp.lua`
- Modify `lua/plugins/autocompletion.lua`
- Modify `lua/plugins/treesitter.lua`
- Modify `lua/plugins/which-key.lua`
- Modify `lua/plugins/guess-indent.lua`

- [x] **Step 1: Disable unused runtime plugins through lazy.nvim**

In the second argument to `require('lazy').setup` in `init.lua`, add:

```lua
performance = {
  rtp = {
    disabled_plugins = {
      'gzip',
      'tarPlugin',
      'tohtml',
      'tutor',
      'zipPlugin',
    },
  },
},
```

Do not disable `netrwPlugin` in this task. Neo-tree is command-loaded and the config does not currently hijack all directory opens.

- [x] **Step 2: Lazy-load LSP on files**

In `lua/plugins/lsp.lua`, add to the plugin spec:

```lua
event = { 'BufReadPre', 'BufNewFile' },
```

- [x] **Step 3: Lazy-load completion on insert**

In `lua/plugins/autocompletion.lua`, change:

```lua
event = 'VimEnter',
```

to:

```lua
event = 'InsertEnter',
```

- [x] **Step 4: Lazy-load which-key later**

In `lua/plugins/which-key.lua`, change:

```lua
event = 'VimEnter',
```

to:

```lua
event = 'VeryLazy',
```

- [x] **Step 5: Lazy-load guess-indent on files**

In `lua/plugins/guess-indent.lua`, add:

```lua
event = { 'BufReadPre', 'BufNewFile' },
```

- [x] **Step 6: Lazy-load Treesitter on files**

In `lua/plugins/treesitter.lua`, replace `lazy = false` with:

```lua
event = { 'BufReadPost', 'BufNewFile' },
cmd = { 'TSInstall', 'TSUpdate', 'TSModuleInfo' },
```

- [x] **Step 7: Validate startup improvement**

Run:

```sh
nvim --headless '+lua print(vim.inspect(require("lazy").stats()))' '+qa'
nvim --headless --startuptime /tmp/tsien-nvim-startup-after-lazy.log '+qa'
tail -n 80 /tmp/tsien-nvim-startup-after-lazy.log
```

Expected: config loads. Startup-loaded plugin count should be lower than the baseline 15. `LazyDone` should not regress.

## Task 4: Complete Frontend/Data LSP Coverage

**Files:**
- Modify `lua/plugins/lsp.lua`

- [x] **Step 1: Add SchemaStore dependency**

In `lua/plugins/lsp.lua`, add to dependencies:

```lua
'b0o/SchemaStore.nvim',
```

- [x] **Step 2: Add HTML, CSS, JSON, and YAML servers**

Add these server configs inside the `servers` table:

```lua
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
```

- [x] **Step 3: Update enabled server list**

Change:

```lua
local server_names = { 'lua_ls', 'vtsls', 'vue_ls', 'eslint', 'tailwindcss', 'basedpyright', 'ruff' }
```

to:

```lua
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
}
```

- [x] **Step 4: Validate enabled LSP configs**

Run:

```sh
nvim --headless '+checkhealth vim.lsp' '+w! /tmp/tsien-nvim-lsp-health.txt' '+qa'
rg -n "html:|cssls:|jsonls:|yamlls:|vtsls:|vue_ls:|basedpyright:|ruff:" /tmp/tsien-nvim-lsp-health.txt
```

Expected: all listed server configurations appear in the health report.

## Task 5: Improve Treesitter And Frontend Editing

**Files:**
- Modify `lua/plugins/treesitter.lua`
- Create `lua/plugins/frontend.lua`

- [x] **Step 1: Add useful parsers**

In `lua/plugins/treesitter.lua`, add to `ensure_installed`:

```lua
'jsonc',
'scss',
'regex',
'jsdoc',
'yaml',
'toml',
```

- [x] **Step 2: Add autotag and color preview plugins**

Create `lua/plugins/frontend.lua`:

```lua
return {
  {
    'windwp/nvim-ts-autotag',
    event = { 'BufReadPost', 'BufNewFile' },
    opts = {
      opts = {
        enable_close = true,
        enable_rename = true,
        enable_close_on_slash = false,
      },
    },
  },
  {
    'NvChad/nvim-colorizer.lua',
    event = { 'BufReadPost', 'BufNewFile' },
    opts = {
      filetypes = {
        'css',
        'scss',
        'html',
        'javascriptreact',
        'typescriptreact',
        'vue',
      },
      user_default_options = {
        mode = 'background',
        tailwind = true,
        RGB = true,
        RRGGBB = true,
        RRGGBBAA = true,
        rgb_fn = true,
        hsl_fn = true,
        css = true,
        css_fn = true,
      },
    },
  },
}
```

- [x] **Step 3: Validate frontend plugins load**

Run:

```sh
nvim --headless '+lua print("CONFIG_LOAD_OK")' '+qa'
nvim --headless +'set ft=typescriptreact' '+lua require("lazy").load({plugins={"nvim-ts-autotag","nvim-colorizer.lua"}}); print("FRONTEND_PLUGINS_OK")' '+qa'
```

Expected: both commands complete and print the OK markers.

## Task 6: Improve Formatting Behavior

**Files:**
- Modify `lua/plugins/conform.lua`

- [x] **Step 1: Add conform formatexpr integration**

Add this to the plugin spec:

```lua
init = function()
  vim.o.formatexpr = "v:lua.require'conform'.formatexpr()"
end,
```

- [x] **Step 2: Reorder Python formatters**

Change Python formatter order to:

```lua
python = { 'ruff_organize_imports', 'ruff_fix', 'ruff_format' },
```

- [x] **Step 3: Add shell formatting**

Add:

```lua
sh = { 'shfmt' },
bash = { 'shfmt' },
```

Also add `shfmt` to `mason-tool-installer` `ensure_installed` in `lua/plugins/lsp.lua`.

- [x] **Step 4: Validate conform config**

Run:

```sh
nvim --headless '+lua require("conform"); print("CONFORM_OK")' '+qa'
```

Expected: prints `CONFORM_OK`.

## Task 7: Apply NvChad-Inspired UI Polish Without Migrating

**Files:**
- Modify `lua/core/options.lua`
- Create `lua/core/theme.lua`
- Modify `lua/plugins/colorschema.lua`
- Modify `lua/plugins/ui.lua`
- Modify `lua/plugins/telescope.lua`

- [x] **Step 1: Align icon assumptions**

If the terminal is using a Nerd Font, change in `lua/core/options.lua`:

```lua
vim.g.have_nerd_font = true
```

This config already uses Nerd Font glyphs in `lua/core/config.lua`, so this change makes plugin UI behavior match the existing icon set.

- [x] **Step 2: Create centralized theme helper**

Create `lua/core/theme.lua`:

```lua
local M = {}

function M.kanagawa_overrides(colors)
  local theme = colors.theme
  return {
    Normal = { bg = 'none' },
    NormalNC = { bg = 'none' },
    StatusLine = { bg = 'none' },
    StatusLineNC = { bg = 'none' },
    NormalFloat = { bg = 'none' },
    FloatBorder = { bg = 'none' },
    FloatTitle = { bg = 'none' },
    TelescopeNormal = { bg = 'none' },
    TelescopeBorder = { bg = 'none' },
    TelescopePromptNormal = { bg = 'none' },
    TelescopePromptBorder = { bg = 'none' },
    TelescopeResultsNormal = { bg = 'none' },
    TelescopeResultsBorder = { bg = 'none' },
    TelescopePreviewNormal = { bg = 'none' },
    TelescopePreviewBorder = { bg = 'none' },
    Pmenu = { fg = theme.ui.shade0, bg = 'none', blend = 0 },
    PmenuSel = { fg = 'none', bg = theme.ui.bg_p2 },
    PmenuSbar = { bg = 'none' },
    PmenuThumb = { bg = theme.ui.bg_p2 },
    LazyNormal = { bg = 'none' },
    LazyBackdrop = { bg = 'none' },
    WhichKeyNormal = { bg = 'none' },
    WhichKeyBorder = { bg = 'none', fg = theme.ui.float.fg_border },
    BlinkCmpMenu = { bg = 'none' },
    BlinkCmpMenuBorder = { bg = 'none' },
    BlinkCmpDoc = { bg = 'none' },
    BlinkCmpDocBorder = { bg = 'none' },
    BlinkCmpSignatureHelp = { bg = 'none' },
    BlinkCmpSignatureHelpBorder = { bg = 'none' },
    TabLine = { bg = 'none' },
    TabLineFill = { bg = 'none' },
    TabLineSel = { bg = 'none' },
  }
end

return M
```

- [x] **Step 3: Use centralized theme helper**

In `lua/plugins/colorschema.lua`, replace the inline `overrides = function(colors) ... end` body with:

```lua
overrides = function(colors)
  return require('core.theme').kanagawa_overrides(colors)
end,
```

- [x] **Step 4: Make Telescope closer to NvChad**

In `lua/plugins/telescope.lua`, update `defaults`:

```lua
defaults = {
  prompt_prefix = '   ',
  selection_caret = ' ',
  entry_prefix = ' ',
  sorting_strategy = 'ascending',
  layout_strategy = 'horizontal',
  layout_config = {
    horizontal = {
      prompt_position = 'top',
      preview_width = 0.55,
    },
    width = 0.87,
    height = 0.80,
  },
}
```

- [x] **Step 5: Tighten bufferline visual density**

In `lua/plugins/ui.lua`, add these `bufferline` options:

```lua
separator_style = 'thin',
indicator = { style = 'underline' },
max_name_length = 24,
max_prefix_length = 18,
tab_size = 18,
show_buffer_close_icons = false,
show_close_icon = false,
```

- [x] **Step 6: Add NvChad-like Snacks toggles**

In the `snacks.nvim` `init` callback in `lua/plugins/ui.lua`, add mappings:

```lua
vim.api.nvim_create_autocmd('User', {
  pattern = 'VeryLazy',
  callback = function()
    Snacks.toggle.option('spell', { name = 'Spelling' }):map('<leader>us')
    Snacks.toggle.option('wrap', { name = 'Wrap' }):map('<leader>uw')
    Snacks.toggle.option('relativenumber', { name = 'Relative Number' }):map('<leader>ur')
    Snacks.toggle.line_number():map('<leader>ul')
    Snacks.toggle.diagnostics():map('<leader>uD')
    Snacks.toggle.option('conceallevel', { off = 0, on = 2, name = 'Conceal' }):map('<leader>uc')
    Snacks.toggle.treesitter():map('<leader>uT')
    Snacks.toggle.inlay_hints():map('<leader>uh')
    Snacks.toggle.indent():map('<leader>ui')
  end,
})
```

- [x] **Step 7: Simplify Snacks dashboard buttons**

In `lua/plugins/ui.lua`, set dashboard keys to:

```lua
keys = {
  { icon = ' ', key = 'f', desc = 'Find File', action = ':Telescope find_files' },
  { icon = ' ', key = 'r', desc = 'Recent Files', action = ':Telescope oldfiles' },
  { icon = '󰈭 ', key = 'g', desc = 'Find Text', action = ':Telescope live_grep' },
  { icon = ' ', key = 'c', desc = 'Config', action = ':Telescope find_files cwd=' .. vim.fn.stdpath 'config' },
  { icon = '󰒲 ', key = 'l', desc = 'Lazy', action = ':Lazy' },
  { icon = ' ', key = 'q', desc = 'Quit', action = ':qa' },
}
```

- [x] **Step 8: Validate UI config loads**

Run:

```sh
nvim --headless '+lua print("UI_CONFIG_OK")' '+qa'
```

Expected: prints `UI_CONFIG_OK`.

## Task 8: Add Diagnostics And Symbol Worklists

**Files:**
- Create `lua/plugins/trouble.lua`
- Modify `lua/plugins/which-key.lua`

- [x] **Step 1: Add Trouble plugin**

Create `lua/plugins/trouble.lua`:

```lua
return {
  'folke/trouble.nvim',
  cmd = 'Trouble',
  opts = {
    win = {
      type = 'split',
      position = 'bottom',
      size = 15,
    },
  },
  keys = {
    { '<leader>xx', '<cmd>Trouble diagnostics toggle<cr>', desc = 'Diagnostics' },
    { '<leader>xX', '<cmd>Trouble diagnostics toggle filter.buf=0<cr>', desc = 'Buffer Diagnostics' },
    { '<leader>xl', '<cmd>Trouble loclist toggle<cr>', desc = 'Location List' },
    { '<leader>xq', '<cmd>Trouble qflist toggle<cr>', desc = 'Quickfix List' },
    { '<leader>xr', '<cmd>Trouble lsp toggle focus=false win.position=right<cr>', desc = 'LSP References' },
    { '<leader>xs', '<cmd>Trouble symbols toggle focus=false<cr>', desc = 'Symbols' },
  },
}
```

- [x] **Step 2: Add which-key group**

In `lua/plugins/which-key.lua`, add:

```lua
{ '<leader>x', group = 'Diagnostics/List' },
```

- [x] **Step 3: Validate Trouble loads**

Run:

```sh
nvim --headless '+lua require("lazy").load({plugins={"trouble.nvim"}}); print("TROUBLE_OK")' '+qa'
```

Expected: prints `TROUBLE_OK`.

## Task 9: Add Browser Debugging For React And Vue

**Files:**
- Modify `lua/plugins/debug.lua`

- [x] **Step 1: Add browser launch and attach configs**

In the JS filetype loop in `lua/plugins/debug.lua`, append these configs to each `dap.configurations[language]`:

```lua
{
  type = 'pwa-chrome',
  request = 'launch',
  name = 'Launch Chrome',
  url = function()
    return vim.fn.input('URL: ', 'http://localhost:3000')
  end,
  webRoot = '${workspaceFolder}',
  sourceMaps = true,
  skipFiles = { '<node_internals>/**', 'node_modules/**' },
},
{
  type = 'pwa-chrome',
  request = 'attach',
  name = 'Attach Chrome',
  port = 9222,
  webRoot = '${workspaceFolder}',
  sourceMaps = true,
  skipFiles = { '<node_internals>/**', 'node_modules/**' },
},
```

- [x] **Step 2: Validate DAP config loads**

Run:

```sh
nvim --headless '+lua require("lazy").load({plugins={"nvim-dap"}}); print("DAP_OK")' '+qa'
```

Expected: prints `DAP_OK`.

## Task 10: Documentation And Final Validation

**Files:**
- Modify `README.md`

- [x] **Step 1: Update README feature list**

Update `README.md` so it explicitly states:

```md
- UI: Kanagawa, transparent centralized highlights, Snacks dashboard/toggles, Lualine, Bufferline, Neo-tree, Telescope.
- Frontend: vtsls, vue_ls, eslint, tailwindcss, html, cssls, jsonls, yamlls, SchemaStore, nvim-ts-autotag, nvim-colorizer.
- Rust: rustaceanvim, rust-analyzer, clippy, rustfmt, codelldb.
- Python: basedpyright, ruff, debugpy, Conform formatting.
- Diagnostics: native LSP diagnostics plus Trouble worklists.
```

- [x] **Step 2: Run full validation**

Run:

```sh
nvim --headless '+lua print("CONFIG_LOAD_OK")' '+qa'
nvim --headless '+checkhealth vim.lsp lazy nvim-treesitter mason' '+w! /tmp/tsien-nvim-health-after.txt' '+qa'
nvim --headless --startuptime /tmp/tsien-nvim-startup-after.log '+qa'
rg -n "ERROR|FAILED" /tmp/tsien-nvim-health-after.txt
```

Expected:

```text
CONFIG_LOAD_OK
```

`rg` should produce no `ERROR` or `FAILED` lines. Mason warnings for non-target languages are acceptable only if they do not affect HTML, CSS, JS/TS, React, Vue, Rust, or Python.

- [x] **Step 3: Compare startup stats**

Run:

```sh
nvim --headless '+lua print(vim.inspect(require("lazy").stats()))' '+qa'
```

Expected: startup-loaded plugin count is lower than the baseline 15, or the same only if a specific UI choice intentionally keeps startup UI loaded. `LazyDone` should not regress meaningfully beyond the original around 113 ms baseline.

- [x] **Step 4: Commit completed optimization**

Run:

```sh
git status --short
git add init.lua README.md lua/core lua/plugins
git commit -m "feat: polish neovim ui and language support"
```

Expected: commit includes only files changed by this plan.

## Deferred Work

- Do not replace Telescope with Snacks picker in this plan. That is a separate UX migration.
- Do not replace Neo-tree with nvim-tree. NvChad uses nvim-tree, but this config already has a stronger Neo-tree setup.
- Do not import `nvchad/ui` or `base46` directly. Borrowing the design ideas keeps this config small and avoids framework lock-in.
- Do not add AI completion until the core UI, performance, and language support are stable.

## Self-Review

- Spec coverage: UI polish, performance, frontend/Rust/Python support, diagnostics, keymaps, DAP, and docs are covered by Tasks 2 through 10.
- Placeholder scan: no task depends on unspecified future work.
- Type consistency: all new plugin files return lazy.nvim plugin specs, and all modified mappings use existing `<leader>` group conventions.
