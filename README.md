# TsienVim

Personal Neovim configuration derived from kickstart.nvim and tuned for frontend, Rust, and Python development.

## Requirements

- Neovim `>= 0.12`
- Git
- A C compiler and `make`
- `tree-sitter` CLI `>= 0.26.1` for parser installation
- `ripgrep`
- `fd`
- Node.js and npm
- Python 3
- Rust toolchain with `cargo`, `rust-analyzer`, `rustfmt`, and `clippy`
- Optional: `lazygit`
- Nerd Font

## Feature Overview

- UI: Tsien Dark (default), Kanagawa, Snacks dashboard/toggles, Lualine, Bufferline, Neo-tree, Telescope.
- Frontend: vtsls, vue_ls, project-aware ESLint/Oxlint and Prettier/Oxfmt selection, tailwindcss, HTML/CSS/JSON/YAML language servers, SchemaStore, nvim-ts-autotag, and nvim-colorizer.
- Rust: rustaceanvim, rust-analyzer, clippy, rustfmt, codelldb.
- Python: basedpyright, ruff, debugpy, venv-selector, neotest-python, Conform formatting.
- Diagnostics: native LSP diagnostics plus Trouble worklists.

## Language Support

- React, Vue, TypeScript, JavaScript, and Node.js through `vtsls`, `vue_ls`, `tailwindcss`, and `blink.cmp`. OXC projects use Oxlint/Oxfmt; other configured projects use ESLint/Prettier.
- Rust through `rustaceanvim`, `rust-analyzer`, routine `cargo check`, on-demand Clippy, `rustfmt`, and DAP integration when `codelldb` is available.
- Python through `basedpyright`, `ruff`, `debugpy`, `venv-selector.nvim`, `neotest-python`, and Conform formatting.
- Markdown rendering through `render-markdown.nvim`; Markdown, JSON, CSS, SCSS, HTML, and YAML formatting through Conform and Prettier-compatible tools.

## Main Plugin Stack

- Plugin manager: `lazy.nvim`
- Completion: `blink.cmp` with LuaSnip snippets
- LSP: native Neovim 0.12+ `vim.lsp.config()` / `vim.lsp.enable()`
- External tools: `mason.nvim`, `mason-lspconfig.nvim`, `mason-tool-installer.nvim`
- Formatting: `conform.nvim`
- Linting: language servers for code, `nvim-lint` for Markdown
- Syntax: `nvim-treesitter`
- Search: `telescope.nvim`
- UI: `kanagawa.nvim`, `lualine.nvim`, `bufferline.nvim`, `noice.nvim`, `snacks.nvim`, `neo-tree.nvim`
- Debugging: `nvim-dap`, `nvim-dap-ui`, `nvim-dap-python`

## Common Commands

```vim
:Lazy
:Mason
:checkhealth
:ConformInfo
:LspInfo
:Typecheck
:TSInstallConfigured
:MasonToolsInstall
```

After initial setup, run `:TSInstallConfigured` to install the configured parsers and `:MasonToolsInstall` to install formatters and debug adapters. Opening files does not run these installation checks.

Rust: `<leader>cC` runs workspace Clippy in a terminal; `<leader>dr` selects a debug target. Debugging plugins and targets load when requested. Python's `<leader>cv` opens the environment selector; project environment discovery is automatic through `core.project`.

`<C-Space>` selects a syntax node in Normal mode and expands it in Visual mode; Visual `<BS>` shrinks it. Files over 1.5 MiB or with very long average lines automatically use plain text rendering and skip automatic formatting. Manual formatting remains available with `<leader>f`.

## Theme

The default theme is the local, dependency-free `tsien-dark`. Change `M.colorscheme` near the top of `lua/core/config.lua`, then restart Neovim. Alternatives include `kanagawa-wave`, `kanagawa-dragon`, and `kanagawa-lotus`.

For a temporary switch, run `:colorscheme tsien-dark` or `:colorscheme kanagawa-wave`. Use `:colorscheme <Tab>` to see available themes.

### Maintaining Tsien Dark

- `lua/theme/palette.lua`: the exact upstream palette, keeping its original names. Start here to adjust the overall look.
- `lua/theme/highlights.lua`: all 281 upstream default highlight definitions, including syntax, diagnostics, and plugin integrations. Change `Comment.italic` here to disable italic comments.
- `colors/tsien-dark.lua`: native colorscheme entry and terminal palette. No plugin is needed to load it.

The first version reproduces gruber-darker.nvim default options at commit `35cb97959ef01f7193c94c404c13ddb3d4346654`. Colors, links, bold/italic styles, terminal colors, cursor styling, help/quickfix window behavior, and semantic-highlight clearing match that baseline. The theme name is `tsien-dark`; upstream `GruberDarker*` highlight names are retained to preserve their links. Upstream attribution and MIT license are in `lua/theme/LICENSE.gruber-darker`. Local changes are independent of future upstream updates.

After saving a palette or highlight edit, run `:colorscheme tsien-dark` to reload both modules. Use `:Inspect` on code to identify the Treesitter/LSP groups involved, and `:highlight GroupName` to inspect UI groups. Prefer links to existing roles over new literal colors. Plugin-specific styling belongs in the highlight table. Avoid adding integrations before comparing the unchanged baseline; plugin defaults should initially behave the same as with gruber-darker.

Before keeping a change, inspect TypeScript/TSX, Vue, Rust, Python, Lua, and Markdown files, plus diagnostics, Telescope, Neo-tree, completion, the statusline, tabs, and a terminal. Check both active and inactive windows and switch away and back. Font rendering, terminal colors, and subjective comfort still need visual review in your own terminal.

Run the theme lifecycle checks without any third-party theme installed:

```sh
NVIM_LOG_FILE=/tmp/tsien-theme.log nvim --headless -u NONE -i NONE --cmd 'set rtp^=.' '+luafile tests/theme.lua'
```

For an optional exact baseline comparison, set `TSIEN_THEME_REFERENCE` to a checkout of gruber-darker.nvim at the documented commit when running the same command. This reference is not part of the configured plugins. Update parity expectations when introducing intentional style changes.

## Validation

```sh
nvim --headless '+lua print("CONFIG_LOAD_OK")' '+qa'
nvim --headless '+lua require("lazy").load({ plugins = { "mason.nvim", "nvim-treesitter", "nvim-lspconfig" } })' '+checkhealth vim.lsp lazy nvim-treesitter mason' '+w! /tmp/nvim-health.txt' '+qa'
nvim --headless --startuptime /tmp/nvim-startup.log '+qa'
nvim --headless -i NONE '+luafile tests/config.lua'
```

## Notes

This is a personal configuration, not a distribution. Prefer small explicit plugin specs over large framework abstractions.

See [DESIGN.md](DESIGN.md) for language-tool ownership and loading invariants.
See [performance measurements](docs/performance-2026-10-09.md) for the optimization results and validation limits.
