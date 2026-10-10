# Purpose

TsienVim is a personal Neovim configuration for JavaScript/TypeScript, Vue, Rust, and Python development. It favors explicit language ownership and predictable loading over distribution-style abstraction.

# System model

- `core.project` detects project roots, local executables, Python environments, and frontend toolchains.
- Native Neovim LSP owns navigation and code intelligence.
- Conform owns formatting. Language-server formatting is disabled where Conform has an explicit formatter.
- Code diagnostics come from language servers. `nvim-lint` is reserved for Markdown.
- Mason integrations install tools, but project-local executables and Rust project toolchains take precedence at runtime.

# Invariants

1. LSP attachment must not load picker, completion, or debugger UI. Telescope and its bookmarks extension load on the first picker action; Blink and snippets load on `InsertEnter`. Rust does not automatically build debugger targets. Python environments are discovered by `core.project`; the environment picker loads on demand.
2. A frontend buffer uses Oxlint when its project opts into OXC tooling; otherwise ESLint may attach when an ESLint configuration exists. They must not attach together.
3. Oxfmt formats projects that opt into it. Other frontend projects use Prettierd or Prettier. Oxlint does not run as a formatter.
4. Python uses Basedpyright for types and Ruff for linting. Ruff hover is disabled, and save-time formatting does not apply broad Ruff fixes.
5. Rust Analyzer follows `rust-toolchain.toml` or the user's rustup default; the editor never forces the stable toolchain.
6. Each external tool has one installer owner: LSP servers use `mason-lspconfig`; formatters, linters without an LSP, and debug adapters use `mason-tool-installer`.
7. Treesitter is registered at startup and starts highlighting on `FileType`, including files opened after startup. Missing parsers retain native syntax. Parser installation and non-LSP tool installation are explicit commands.
8. Snacks owns document reference highlighting. No second CursorHold handler sends duplicate LSP requests.
9. Files classified by Snacks as big files have no syntax parsing, automatic completion, indent/scope rendering, or save-time formatting. This includes files over 1.5 MiB and files with excessively long average lines.

# Key decisions

- Keep the existing plugin stack. Optimize loading dependencies instead of removing useful development features.
- Register Treesitter and rustaceanvim eagerly because their current versions rely on runtime paths and filetype plugins. Their expensive language work remains buffer-specific.
- Use `cargo check` for routine Rust diagnostics, retaining build-script and procedural-macro analysis. `<leader>cC` runs full workspace Clippy explicitly in a terminal; `<leader>dr` loads debugger targets on demand.
- Keep formatting synchronous before save so the file on disk is formatted. Budget 300 ms for Lua, 750 ms for Markdown/SQL, and 500 ms otherwise. Slow formatting remains available through the asynchronous manual command. Formatter failures are visible.
- Big files use plain text rendering rather than falling back to expensive legacy syntax. Snacks quickfile is disabled so it cannot independently start another highlighter.
- Treesitter query compilation is scheduled after file opening, and context loads at `VeryLazy`. This allows an initial frame before expensive first-language query compilation. Existing native highlighters are reused.
- Treesitter owns Vue colors. Native semantic tokens are disabled for Vue buffers with Neovim 0.12's supported buffer filter; TypeScript/JavaScript buffers keep their semantic tokens.

# Interfaces and data flow

- `core.project.eslint_root()` and `core.project.oxlint_root()` are mutually exclusive inputs to LSP root selection.
- `core.project.oxfmt_root()` selects the frontend Conform formatter.
- `:Typecheck` runs the nearest package `typecheck` script, or falls back to project-local `tsc --noEmit`. TypeScript diagnostics are written to quickfix.
- Python interpreter discovery prefers active environments, then project virtual environments, then the system interpreter.

# Failure behavior

- Missing optional project tools do not start duplicate fallbacks. Commands report a direct error instead.
- `sqls` is enabled only when an existing binary is available or Go can build the Mason package.
- Failed typechecks open parsed TypeScript diagnostics in quickfix; unparseable command failures are reported verbatim.

# Validation strategy

- Load the configuration headlessly and run plugin health checks.
- Verify Blink and Telescope remain unloaded before their first user action.
- Test ESLint and OXC fixture projects to confirm exclusive LSP ownership.
- Test a Python virtual environment and a Rust project with a toolchain override.
- Compare repeated warm `--startuptime` medians rather than single-run or plugin marketing figures.
- Verify initial and subsequent TypeScript/Rust buffers have active highlighters, and the native node-selection shortcuts expand/shrink selections.
- Verify a 1.8 MiB file opens with a UI, skips parsing/rendering helpers, and skips automatic formatting.
- Run `tests/config.lua` inside the normal configuration for loading and formatting invariants. Measure the previous workspace snapshot and current configuration under the same UI client and cache conditions.

# Theme ownership

- `core.config.colorscheme` selects the default. `init.lua` applies it once after Lazy has configured eager theme plugins. Third-party specs only configure their themes, so they cannot compete to select the default.
- Tsien Dark is a native local colorscheme (`colors/tsien-dark.lua`) with no third-party runtime dependencies. Its initial baseline exactly reproduces default gruber-darker.nvim at `35cb97959ef01f7193c94c404c13ddb3d4346654`; Kanagawa remains available for switching. The upstream plugin is removed from the configured dependencies; a separate checkout can be supplied for optional comparison tests.
- `theme.palette` preserves the upstream palette names and values. `theme.highlights` contains upstream definitions and local adjustments as plain tables, including upstream highlight names and links. Upstream MIT attribution is retained in `lua/theme/LICENSE.gruber-darker`.
- Loading and lifecycle match upstream: clear highlights when a theme is already active, enable true color, apply definitions, append cursor styling, set all ANSI and foreground/background terminal colors, register help/quickfix window mappings, and clear LSP semantic highlight styles on ColorScheme. Semantic tokens themselves remain enabled according to existing LSP policy. Theme autocmds are removed on ColorSchemePre.
- Palette and highlight modules are reloaded so edits can be reapplied without restarting. Tsien Dark has its own colorscheme name and autocmd group; shared `GruberDarker*` highlight names preserve the baseline definitions.
- The initial baseline introduced no extra plugin integrations, color adjustments, syntax reset, or forced background mode. Current local adjustments are documented below. New terminal jobs pick up the palette; existing jobs may retain previous colors.
- `tests/theme.lua` checks reload and switching consistency without external dependencies. With `TSIEN_THEME_REFERENCE` set, it also compares every highlight definition and resolved appearance, terminal colors, cursor and background mode against the pinned upstream reference. It also checks sidebar behavior, reload and switching lifecycle. Once intentional customization begins, document differences and adjust parity assertions accordingly. Visual review remains necessary for terminal and plugin rendering.

## Readability adjustments

- Preserve theme lifecycle behavior. Yellow is slightly darker (`#ffdd33` → `#e6c72e`) and green is slightly darker (`#73d936` → `#68c431`); these changes also apply to their terminal colors. Other inherited palette values retain the baseline. Property and modern member captures use `niagara` rather than the dim `niagara-1`.
- Search matches use yellow text on a dark warm background (`#403a20`); the current/incremental match uses a yellow background and dark text. Visual selections explicitly use the body foreground to preserve readability over all syntax colors. Identifiers use body text rather than the brighter `fg+1`. Strings are upright while comments retain italics.
- Separate UI roles avoid changing inherited syntax colors: ordinary line numbers use `ui-muted` (`#8a817c`), floating and completion borders use `border` (`#78716c`), and completion descriptions/details/kinds use `menu-muted` (`#b2a9a3`). Blink gets explicit theme groups for labels, yellow matched letters, muted metadata, and borders. Its selection group defines only a background so the selected row does not overwrite matched letters or metadata foregrounds.
- Inline diagnostic messages use non-bold text: red errors, brown warnings, quartz information, and wisteria hints. Gutter signs and floating diagnostics retain severity colors. Message content and LSP diagnostic display settings remain unchanged.
- MatchParen and ErrorMsg use black text on their colored backgrounds. Folded text uses the normal foreground for readability. Diff lines have the existing raised background; DiffText uses the selection background, bold text and underline to distinguish changed characters.
- Tests enforce at least 4.5:1 text contrast for changed reading roles, search, selections, line numbers, and completion labels/metadata on both normal and selected backgrounds. Completion borders maintain at least 3:1 contrast. Quieter inline warnings, preserved warning-sign emphasis, and distinct diff character emphasis remain checked. Optional upstream comparison excludes only the documented changed definitions and their inherited appearance; all other definitions and terminal behavior remain checked after applying the documented yellow/green substitutions.

- Native Vue syntax gives the whole script region the `javaScript` group, which upstream links to yellow Special. Tsien Dark links that region to Identifier for readable fallback text. Parser installation remains explicit on each machine; Treesitter startup failures for configured languages show the underlying error and `:TSInstallConfigured` recovery command.

- The nvim-web-devicons compatibility entry explicitly loads mini.icons through Lazy before creating the mock, ensuring setup options and ColorScheme callbacks are registered. Tsien Dark defines all nine MiniIcons color groups directly from its palette so icon colors do not inherit unrelated diagnostic or syntax roles.
