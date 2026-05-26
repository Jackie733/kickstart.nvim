# Neovim Config Optimization Design

Date: 2026-05-26

## Goal

Optimize this personal Neovim configuration for frontend React/Vue/TypeScript/JavaScript/Node.js work, with solid Rust and Python support. Keep the configuration small, explicit, maintainable, visually polished, and fast.

The work should preserve the current kickstart-style module layout and avoid turning the config into a full distribution clone.

## Current Findings

- The config currently loads successfully on `NVIM v0.12.0-dev`.
- `nvim-lspconfig` has moved to the `vim.lsp.config()` and `vim.lsp.enable()` API for Neovim 0.11+; the old `require('lspconfig').setup()` framework is deprecated.
- `mason-lspconfig` v2 automatically enables installed LSP servers by default. In this config that causes accidental enabled configurations, including `pyright`, `ruff`, `rust_analyzer`, `clangd`, and `stylua`.
- The existing `mason-lspconfig` `handlers` setup no longer applies as intended, so custom server settings for `vtsls`, `vue_ls`, and others are not reflected in `:checkhealth vim.lsp`.
- `vtsls` is enabled without `vue` in its active filetypes, so Vue hybrid TypeScript support is incomplete.
- Python currently risks overlapping `basedpyright`, `pyright`, and `ruff` behavior.
- Rust should be owned by `rustaceanvim`; enabling `rust_analyzer` separately can cause duplicate LSP clients.
- `lua/plugins/ui.lua` has a top-level `require 'blink.cmp.config.signature'` that is unused and forces earlier completion-related loading.
- `lazy.nvim` reports `luarocks`/`hererocks` health warnings even though current plugins do not need rocks.

## References

- `nvim-lspconfig` official README: use `vim.lsp.config()` and `vim.lsp.enable()` for Neovim 0.11+.
- `mason-lspconfig.nvim` official README: v2 defaults to automatic server enabling via `vim.lsp.enable()`.
- Vue language-tools Neovim wiki: Vue 3 language server uses `vue_ls` plus `vtsls` with `@vue/typescript-plugin`.
- LazyVim language extras: `vtsls` for TypeScript, `vue_ls + vtsls` for Vue, `basedpyright/pyright + ruff` split for Python, `rustaceanvim` for Rust.
- Snacks.nvim README: `bigfile`, `quickfile`, `dashboard`, `input`, `notifier`, `indent`, `scope`, and `words` are lightweight QoL modules.

## Approach

Use a modernized small-step refactor:

- Keep `lua/core/*` and `lua/plugins/*`.
- Keep the current plugin choices unless there is a direct bug, duplication, or performance reason to change.
- Move LSP setup to explicit Neovim 0.11+ APIs.
- Prevent Mason from enabling arbitrary installed LSPs.
- Preserve Telescope, Neo-tree, Lualine, Bufferline, Noice, Kanagawa, Snacks, Blink, Conform, nvim-lint, nvim-dap, and rustaceanvim.

Avoid a full LazyVim/AstroNvim/NvChad migration. Borrow proven settings only where they fit this codebase.

## LSP Design

`lua/plugins/lsp.lua` will:

- Configure diagnostics and shared `LspAttach` keymaps as it does today, but with less kickstart tutorial commentary.
- Define shared capabilities through `blink.cmp`.
- Configure target servers with `vim.lsp.config()`:
  - `lua_ls`
  - `vtsls`
  - `vue_ls`
  - `eslint`
  - `tailwindcss`
  - `basedpyright`
  - `ruff`
- Enable only those explicit servers with `vim.lsp.enable()`.
- Configure `mason-lspconfig` with `automatic_enable = false`.
- Install only needed LSP servers through `mason-lspconfig.ensure_installed` and related tools through `mason-tool-installer`.

Server behavior:

- TypeScript/JavaScript: use `vtsls`, enable workspace TypeScript SDK, server-side fuzzy match, update imports on file moves, and practical inlay hints.
- Vue: use `vue_ls` for SFC HTML/CSS support and `vtsls` for TypeScript, with `@vue/typescript-plugin` from Mason's `vue-language-server` package.
- ESLint: enable workspace auto-detection and code actions, but do not duplicate formatting responsibility unless explicitly needed.
- Tailwind CSS: keep for frontend filetypes and rely on project root detection.
- Python: use `basedpyright` for type intelligence and `ruff` server for lint/fix/organize-import capabilities; disable `ruff` hover so `basedpyright` owns hover.
- Rust: do not enable `rust_analyzer` here; leave it to `rustaceanvim`.

## Formatting And Linting

`conform.nvim` remains the formatter owner:

- Lua: `stylua`
- Python: `ruff_fix`, `ruff_format`, `ruff_organize_imports`
- JS/TS/React/Vue: `prettierd`, then `prettier`
- Common frontend/data formats: `json`, `jsonc`, `css`, `scss`, `html`, `yaml`, `markdown`, and `markdown.mdx` where supported by available Prettier tooling

`nvim-lint` remains narrow:

- Keep linting where LSP does not already cover the same diagnostics.
- Avoid adding ESLint or Ruff duplicate linting if their LSP clients are active.

## Debugging

Keep `nvim-dap` and `nvim-dap-ui`.

- Ensure Mason installs `debugpy`, `js-debug-adapter`, and `codelldb`.
- Keep Python debug support through `debugpy`.
- Add JS/TS Node launch/attach configurations using `js-debug-adapter`.
- Let `rustaceanvim` handle Rust debuggables and adapter integration when possible.

## UI And Performance

- Remove the unused top-level Blink signature require from `ui.lua`.
- Keep Kanagawa Dragon and transparent styling, but reduce fragile highlight duplication where possible.
- Set a global rounded floating border with `vim.o.winborder = 'rounded'`.
- Enable Snacks `bigfile` and `quickfile`; keep dashboard, input, notifier, indent, scope, and words.
- Do not replace Telescope with Snacks picker in this pass. That would be a separate UX migration.
- Disable lazy.nvim rocks support to remove irrelevant health warnings.
- Keep startup-impacting plugins lazy where feasible; avoid moving more plugins to startup.

## Documentation

Update `README.md` from stock kickstart text into a concise personal configuration README covering:

- Supported Neovim version: `>= 0.11`
- Main language support
- Required external tools
- Mason-managed tools
- Key plugin stack
- Basic validation commands

## Validation

Run:

```sh
nvim --headless '+lua print("CONFIG_LOAD_OK")' '+qa'
nvim --headless '+checkhealth vim.lsp lazy nvim-treesitter mason' '+w! /tmp/nvim-health.txt' '+qa'
nvim --headless --startuptime /tmp/nvim-startup.log '+qa'
```

Inspect:

- `:checkhealth vim.lsp` enabled configurations should no longer include accidental `pyright`, `rust_analyzer`, `clangd`, or `stylua` unless intentionally enabled later.
- `vtsls` should include `vue` when Vue support is configured.
- Rust files should be handled by `rustaceanvim`.
- Startup should not introduce a large regression.

## Out Of Scope

- Full conversion to LazyVim, AstroNvim, or NvChad.
- Replacing Telescope with Snacks picker.
- Adding test runner frameworks such as neotest.
- Adding AI completion.
- Supporting Neovim 0.10 or older.
