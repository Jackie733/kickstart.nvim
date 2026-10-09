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

- UI: Gruber Darker (default), Kanagawa, Snacks dashboard/toggles, Lualine, Bufferline, Neo-tree, Telescope.
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
- UI: `gruber-darker.nvim`, `kanagawa.nvim`, `lualine.nvim`, `bufferline.nvim`, `noice.nvim`, `snacks.nvim`, `neo-tree.nvim`
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

The default theme is `gruber-darker`. Change `local colorscheme` at the top of `lua/plugins/colorschema.lua` to persist a different theme, then restart Neovim. Available alternatives include `kanagawa-wave`, `kanagawa-dragon`, and `kanagawa-lotus`.

For a temporary switch, run `:colorscheme kanagawa-wave` or `:colorscheme gruber-darker`. Use `:colorscheme <Tab>` to see available themes. Gruber Darker preferences can be customized in its `opts` table in the same file.

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
