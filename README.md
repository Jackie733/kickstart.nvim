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

## Feature Overview

- UI: Kanagawa, transparent centralized highlights, Snacks dashboard/toggles, Lualine, Bufferline, Neo-tree, Telescope.
- Frontend: vtsls, vue_ls, eslint, tailwindcss, html, cssls, jsonls, yamlls, SchemaStore, nvim-ts-autotag, nvim-colorizer.
- Rust: rustaceanvim, rust-analyzer, clippy, rustfmt, codelldb.
- Python: basedpyright, ruff, debugpy, Conform formatting.
- Diagnostics: native LSP diagnostics plus Trouble worklists.

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
nvim --headless '+lua require("lazy").load({ plugins = { "mason.nvim", "nvim-treesitter", "nvim-lspconfig" } })' '+checkhealth vim.lsp lazy nvim-treesitter mason' '+w! /tmp/nvim-health.txt' '+qa'
nvim --headless --startuptime /tmp/nvim-startup.log '+qa'
```

## Notes

This is a personal configuration, not a distribution. Prefer small explicit plugin specs over large framework abstractions.
