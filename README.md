# TsienVim

Personal Neovim configuration derived from kickstart.nvim and tuned for frontend, Rust, and Python development.

## Requirements

- Neovim `>= 0.12`
- Git
- A C compiler and `make`
- `tree-sitter` CLI `>= 0.26.1` for parser installation
- `ripgrep`
- `fd`
- Node.js `>= 20.19` and npm
- Python 3
- Rust toolchain with `cargo`, `rust-analyzer`, `rustfmt`, and `clippy`
- Optional: `lazygit`
- Nerd Font

On macOS, install the parser build tool with `brew install tree-sitter-cli`.
Homebrew's `tree-sitter` library is a separate package and does not provide this command.

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
:TsienCheck
:TsienSetup
:TsienSetup!
:TSInstallConfigured
:MasonToolsInstall
```

Run `:TsienSetup` once on a new machine. It checks system prerequisites, installs missing Homebrew dependencies on macOS, prepares the current project's Rust components, installs language servers/formatters/debug adapters, and synchronizes parsers with the installed Treesitter plugin. Repeating it skips usable tools. It preserves the project's Rust toolchain; a default stable toolchain is only created when no default or project override exists. System compilers and unsupported package managers receive actionable manual instructions rather than a shell installer.

`:TsienCheck` is read-only and shows versions, missing executables, parser/query compatibility, managed tools, and Rust component availability. Both commands show progress in a result window (`q` closes it) and save the result in `stdpath('state')/tsien-environment.log`. Failed downloads and installation errors remain visible; detailed upstream logs are available with `:MasonLog` and `:TSLog`. Run setup from the target project when preparing a pinned Rust toolchain.

`:TsienSetup!` rebuilds all configured parsers when an update causes incompatible parsing/highlighting. Restart Neovim after replacing loaded parsers: the current process may still hold the old library. Installed packages are not blindly updated to newer versions. Existing parser/tool installation commands remain available.

Ordinary startup registers commands without running a global scan or starting installers. Opening a file with a missing configured parser installs that parser asynchronously if the required CLI/compiler are available, then restores highlighting and indentation in still-valid buffers. Multiple buffers share one installation; failed languages are not retried on every file open. Missing system tools point to `:TsienSetup`. Parser incompatibility points to `:TsienSetup!` and a restart.

Rust analysis prefers the actual binary belonging to the project's active toolchain, falls back to Mason's standalone binary when that component is absent, and never treats a broken rustup proxy as a working server. Project packages such as Vue, React, TypeScript, pytest, and framework build/runtime dependencies are still managed by each project.

Rust: `<leader>cC` runs workspace Clippy in a terminal; `<leader>dr` selects a debug target. Debugging plugins and targets load when requested. Python's `<leader>cv` opens the environment selector; project environment discovery is automatic through `core.project`.

`<C-Space>` selects a syntax node in Normal mode and expands it in Visual mode; Visual `<BS>` shrinks it. Files over 1.5 MiB or with very long average lines automatically use plain text rendering and skip automatic formatting. Manual formatting remains available with `<leader>f`.

## Theme

The default is `M.colorscheme = 'auto'`: Neovim reports the terminal background through an OSC 11 query (with `$COLORFGBG` as a fallback for terminals that export it), and `core.theme` loads `tsien-dark` for dark terminals or `tsien-light` for light terminals. If detection is unavailable, `'background'` stays dark, so the default remains dark. To pin a theme, set `M.colorscheme` to a name such as `tsien-dark`, `tsien-light`, `kanagawa-wave`, `kanagawa-dragon`, or `kanagawa-lotus`; background changes no longer swap pinned themes, and a pinned Tsien theme restores its own background.

In auto mode, runtime background changes also switch themes: Neovim re-queries the terminal after resuming from suspend, and `:set background=light` or `:set background=dark` switches immediately. A manually selected third-party theme is left alone. For a direct switch, run `:colorscheme tsien-dark` or `:colorscheme tsien-light`. Use `:colorscheme <Tab>` to see available themes.

### Maintaining Tsien themes

- `lua/core/theme.lua`: resolves `auto` from the terminal background, applies the selected colorscheme, and swaps Tsien themes when `'background'` changes.
- `lua/theme/palette.lua`: the upstream dark palette with local color adjustments, keeping its original names. Start here to adjust the dark look.
- `lua/theme/highlights.lua`: shared highlight definitions plus dark readability adjustments, including syntax, diagnostics, and plugin integrations. Change `Comment.italic` here to disable italic comments.
- `lua/theme/palette-light.lua` and `lua/theme/highlights-light.lua`: Catppuccin Latte surfaces, One Light inspired syntax accents, and explicit light-background overrides.
- `colors/tsien-dark.lua` and `colors/tsien-light.lua`: native colorscheme entries and terminal palettes. No plugin is needed to load them.

The first version reproduces gruber-darker.nvim default options at commit `35cb97959ef01f7193c94c404c13ddb3d4346654`. Colors, links, bold/italic styles, terminal colors, cursor styling, help/quickfix window behavior, and semantic-highlight clearing match that baseline. File icons use explicit `MiniIcons*` palette colors: blue for TypeScript/Lua, green for Vue, yellow for JSON, and brown for Rust. The theme name is `tsien-dark`; upstream `GruberDarker*` highlight names are retained to preserve their links. Upstream attribution and MIT license are in `lua/theme/LICENSE.gruber-darker`. Local changes are independent of future upstream updates. Current adjustments brighten property/member captures using the existing `niagara` color; soften inline diagnostics without bold text while retaining severity-colored gutter signs; improve matching-bracket, error-message and folded-text contrast; and distinguish changed diff characters with a stronger background and underline. Yellow (`#e6c72e`) and green (`#68c431`) are slightly darker than upstream for softer emphasis; other palette values retain the baseline.

`tsien-light` uses Catppuccin Latte base (`#eff1f5`), text (`#4c4f69`), and layered UI surfaces to better match a Latte terminal, while retaining One Light inspired syntax and ANSI colors. It reuses `theme.highlights` and overrides groups whose dark-background assumptions do not carry over: statusline and float titles use body text, diff surfaces are tinted, severity colors are remapped, and icons/rainbow delimiters use explicit hues. Muted text and diagnostic accents are adjusted for readability on the light surfaces. Both themes set `'background'` when loaded directly and clear `g:colors_name` before doing so; `core.theme` marks terminal-driven reloads so a theme does not force its old background back before the matching theme is selected. New embedded terminal jobs use the updated foreground and background; existing jobs may retain previous colors.

In the light theme, window separators use Latte mantle (`#e6e9ef`) on base (`#eff1f5`) for a faint boundary. Both `WinSeparator` and Neo-tree's separator groups are defined explicitly. Git gutter signs and Neo-tree Git labels use foreground-only colors; actual diff views retain their tinted backgrounds.

The `<leader>gg` LazyGit launcher passes the current Neovim background as `NVIM_BACKGROUND`. For a custom delta diff renderer, use `--${NVIM_BACKGROUND:-dark}` instead of a fixed `--dark` flag so its side-by-side diff follows the selected theme; outside Neovim this falls back to dark.

After saving a palette or highlight edit, run `:colorscheme tsien-dark` or `:colorscheme tsien-light` to reload the modules. Use `:Inspect` on code to identify the Treesitter/LSP groups involved, and `:highlight GroupName` to inspect UI groups. Prefer links to existing roles over new literal colors. Plugin-specific styling belongs in the highlight table. Keep intentional differences documented and prefer changes to specific roles over global palette substitutions.

Reading refinements preserve the inherited syntax palette: ordinary search matches use a dark warm background while the current match uses yellow; selections use a uniform readable foreground; identifiers share the body text color; strings are upright and comments remain italic. Line numbers and floating borders are clearer through separate UI roles. Blink completion has explicit yellow matched letters, quieter metadata, and subdued borders; the selected-row background preserves these text colors.

Vue files require the `vue`, `typescript`, `javascript`, and `css` parsers on each machine. Run `:TSInstallConfigured`, wait for installation to finish, then restart Neovim. If `:Inspect` reports only `Syntax: javaScript` and `:set syntax?` reports `vue`, native syntax is being used instead of Treesitter. Tsien Dark makes the fallback script text neutral rather than yellow; full code-role colors require the parsers. Treesitter startup failures for configured languages report the error and installation command. If `:Inspect` still shows only native syntax, run `:lua vim.treesitter.start(0)` in that buffer to expose the startup error.

Before keeping a change, inspect TypeScript/TSX, Vue, Rust, Python, Lua, and Markdown files, plus diagnostics, Telescope, Neo-tree, completion, the statusline, tabs, and a terminal. Check both active and inactive windows and switch away and back. Font rendering, terminal colors, and subjective comfort still need visual review in your own terminal.

Run the theme lifecycle checks without any third-party theme installed:

```sh
NVIM_LOG_FILE=/tmp/tsien-theme.log nvim --headless -u NONE -i NONE --cmd 'set rtp^=.' '+luafile tests/theme.lua'
NVIM_LOG_FILE=/tmp/tsien-theme-light.log nvim --headless -u NONE -i NONE --cmd 'set rtp^=.' '+luafile tests/theme-light.lua'
NVIM_LOG_FILE=/tmp/tsien-theme-auto.log nvim --headless -u NONE -i NONE --cmd 'set rtp^=.' '+autocmd VimEnter * ++nested luafile tests/theme-auto.lua'
```

For an optional baseline comparison of unchanged definitions, set `TSIEN_THEME_REFERENCE` to a checkout of gruber-darker.nvim at the documented commit when running the same command. This reference is not part of the configured plugins. The comparison allows the documented changed groups; contrast and hierarchy checks validate those adjustments.

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
