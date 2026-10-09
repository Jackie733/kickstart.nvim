# Neovim performance optimization — 2026-10-09

The comparison uses the workspace immediately before these edits, including its existing uncommitted changes. Both configurations use Neovim 0.12.2, the same installed plugins and warmed cache, and an attached 120×40 UI. ShaDa is disabled. Each startup result is the median of five warm runs after a discarded warmup. Rust builds use offline Cargo and isolated target directories under `/tmp`.

## First screen

| File/project | Before | After |
| --- | ---: | ---: |
| Empty dashboard | 56.0 ms | 60.5 ms |
| Configuration Lua file | 96.1 ms | 91.5 ms |
| Small Python file | 127.3 ms | 104.9 ms |
| Small TypeScript file | 334.9 ms | 240.2 ms |
| Rust: minigrep | 208.7 ms | 123.3 ms |
| Rust: reader/native workspace | 228.7 ms | 131.8 ms |
| Rust: atelier/Leptos | 249.8 ms | 151.5 ms |

These are first-screen times, not full LSP readiness or typing latency. Initial Treesitter query compilation is scheduled after opening the file; its cost remains. Empty startup is approximately unchanged and slightly slower in this sample because supported Treesitter/Rust runtime registration is eager.

## Rust analysis

One additional warm run per project completed indexing, a valid hover request, and a `cargo check` triggered by a save notification without writing the source file.

| Project | Indexing reached idle | rust-analyzer peak RSS |
| --- | ---: | ---: |
| minigrep | 3.6 s | 651 MiB |
| reader/native | 5.1 s | 1124 MiB |
| atelier | 17.5 s | 1832 MiB |

This is evidence that background analysis remains functional, not a controlled claim that all analysis or memory usage improved. Dependency compilation, standard-library indexing, and procedural macros remain substantial work. Build scripts and macro support are retained.

Rust startup loads 25 plugins rather than 33 in this comparison. Telescope, Blink, and DAP stay unloaded until requested. Automatic debugger-target building is disabled; normal diagnostics use `cargo check`, and `<leader>cC` explicitly runs workspace Clippy in a terminal.

## Functional validation

- `tests/config.lua` passes with the normal configuration. It covers delayed/highlighter initialization, filetype changes, native node selection with mini.ai enabled, missing-parser fallback, closed buffers, lazy loading, formatting budgets, and large-buffer guards.
- UI checks confirm subsequent TypeScript and Rust files have active highlighters and attached language servers. The Rust client is reused.
- A 1.8 MiB / 140,000-line TypeScript file opens to the first screen in approximately 102 ms in the final UI check. A minified file also downgrades correctly. Both have no highlighter, legacy syntax, LSP clients, completion, indent/scope rendering, or save formatting.
- A Vue fixture attaches both `vtsls` and `vue_ls` without the previous Neovim 0.12 semantic-token filter error. Treesitter supplies Vue colors; TS/JS buffers retain native semantic tokens.
- Saving an unformatted Lua fixture produces the expected formatted file. The Rust Clippy shortcut creates a terminal task and exits successfully. DAP adapters still configure on demand.
- Plugin health checks report no errors. Blink's informational warning about dynamically enabled providers remains.
- StyLua checks and `git diff --check` pass. Existing unrelated workspace edits are retained; plugin revisions are not updated.

Raw startup logs, UI snapshots, and the comparison summary are stored in `/tmp/tsien-nvim-performance`. Rust analysis samples are stored in `/tmp/tsien-rust-audit/after-optimization.json`; these temporary files are not required to use the configuration.

## Day-to-day behavior

Run `:TsienSetup` after initial setup or when adding tools, and `:TsienCheck` for read-only verification. Missing configured parsers are now installed asynchronously on first use; regular startup does not run a global environment scan. Project-local Python environment discovery remains automatic; `<leader>cv` loads the environment selector when needed. Automatic formatting remains before save with a bounded timeout; `<leader>f` performs manual formatting asynchronously.

## Environment setup follow-up

The current local validation uses Neovim 0.12.1, not the historical 0.12.2 comparison above. Environment commands only register at startup; global scans and system installers run when requested. Rust binary resolution runs on demand in the opened project's directory and checks the real toolchain component before using a standalone fallback.

Five warm runs with a 120×40 attached UI, after one discarded warmup, measured median first-screen times of 37.2 ms (empty), 92.9 ms (Rust), 138.5 ms (TypeScript), 165.3 ms (TSX), 162.7 ms (Vue), and 120.7 ms (Python). A 140,000-line / 2.24 MB TypeScript fixture opened in 66.2 ms. These include process creation and the first completed screen after VimEnter; they do not measure background analysis readiness. The samples used for frontend/Python were small controlled projects; Rust used `devctl/src/main.rs`.

Validation:

- `tests/config.lua` and `tests/theme.lua` pass.
- `tests/environment.lua` checks old/invalid/missing CLI detection, broken rustup fallback, shared parser requests, failed-download suppression, subprocess spawn failure, concurrent-setup prevention, simulated system-package repair, and registry failure reporting. It ends with a real read-only environment check.
- `tests/parser-auto.lua` runs a real Rust parser installation in a private directory. Three buffers share one installation, live buffers gain highlighting and indentation without a restart, and deleted/changed buffers are skipped. Set `TSIEN_TEST_DIR` to a fresh private directory before running it.
- `tests/environment-ui.lua` verifies result-window contents, its close shortcut, and buffer reuse.
- Real initialization installed missing Oxfmt, Prettier, and shfmt plus Rust components. Forced repair rebuilt all configured parsers; a fresh process then passed environment and parser/query checks.
- TypeScript, JSX, TSX, Vue, Python, and Rust attach the expected servers, return a valid hover, and expose available formatters. Existing plugin lockfile changes were preserved.
