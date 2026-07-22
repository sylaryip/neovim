---
name: vscode-neovim-config
description: Configure the asvetliakov/vscode-neovim VS Code extension for users who only use VS Code but want full Vim/Neovim editing power. This skill should be used when a user asks to set up vscode-neovim, use Vim keybindings inside VS Code, fix vscode-neovim issues (multi-cursor, folds, LSP), choose which Neovim plugins work under vscode-neovim, or migrate a LazyVim / terminal-Neovim config into VS Code.
agent_created: true
---

# vscode-neovim Configuration

## Purpose
Provide a known-good, zero-UI-conflict Neovim configuration for the `vscode-neovim`
extension, plus hard-won fixes for the traps that break a naive terminal-Neovim
config when it is embedded in VS Code.

## When to use
- User wants Vim/Neovim keybindings inside VS Code.
- User reports vscode-neovim problems: `zc` → `E490: No fold found`;
  multi-cursor `c` edits only the first line; `Cmd+D` jumps into Insert mode
  unexpectedly; plugins "not working".
- User wants to migrate a LazyVim / kickstart / custom config into VS Code.

## Core principle (load-bearing)
vscode-neovim embeds a **real Neovim process**, but VS Code owns the **display
layer**. Neovim computes; VS Code renders. Any plugin that needs Neovim to draw
its own UI will NOT work and must be dropped in favor of a VS Code native
capability:

- DO NOT install (they need Neovim to render, will conflict or no-op):
  Telescope, nvim-tree, neo-tree, lualine, bufferline, nvim-cmp / blink.cmp,
  mason + nvim-lspconfig, gitsigns UI, nvim-tree, dashboard.
- DELEGATE to VS Code (bridge with `require('vscode').action(...)`):
  file search (`<leader>ff` → `workbench.action.quickOpen`),
  global search (`<leader>fg` → `workbench.action.findInFiles`),
  rename (`<leader>cr` → `editor.action.rename`),
  format (`<leader>cf` → `editor.action.formatDocument`),
  quickFix (`<leader>ca` → `editor.action.quickFix`), Git, completion,
  LSP hover (`K` / `gd` are built-in by the extension), tabs, file tree, status bar.
- Wrap all VS Code bridges in `if vim.g.vscode then ... end` so the same
  config still works as a standalone terminal `nvim`.

## Safe plugin set (zero native build, always works)
`vim-surround`, `vim-repeat`, `vim-commentary`, `leap.nvim` (or `flash.nvim`),
`vscode-multi-cursor.nvim`. Manage them with `lazy.nvim`.
See `references/init.lua` for the full known-good file, and
`references/keybindings.json` for the matching VS Code keybindings.

## Trap 1 — Folds (zc/zo → E490: No fold found)
VS Code manages folds itself; Neovim's `foldmethod` is a separate system. Bridge
the `z` keys to VS Code commands:
`zc`→`editor.fold`, `zo`→`editor.unfold`, `zM`→`editor.foldAll`,
`zR`→`editor.unfoldAll`, `zC`→`editor.foldRecursively`,
`zO`→`editor.unfoldRecursively`.

## Trap 2 — Multi-cursor (THE big one)
Symptoms: `Cmd+D` then `c` edits only the first cursor; or `mi`/`ma` do nothing;
or `Cmd+D` jumps into Insert on its own.

Root cause: vscode-neovim only handles multi-cursor reliably in **Insert /
Visual-line / Visual-block** mode. Normal-mode operators (`c`, `ciw`) act only
on the primary cursor.

RIGHT way — use `vscode-multi-cursor.nvim` and its own `mc` system:

1. Install `vscode-neovim/vscode-multi-cursor.nvim` with
   `cond = not not vim.g.vscode`, `opts = {}` (this enables `default_mappings`:
   `mc`, `mi`, `ma`, `mcc`, `mcs`, `mcw`).
2. In `init.lua` (inside `if vim.g.vscode`), map
   `<C-d>` → `mciw*<Cmd>nohlsearch<CR>` with `remap = true`. This marks the word
   under the cursor into the plugin's cursor STATE and jumps to the next match —
   staying in **Normal** mode.
3. In VS Code `keybindings.json`, forward `Cmd+D` to neovim `<C-d>` with
   `when: "editorTextFocus && neovim.mode == 'normal'"`.
4. Workflow: `Cmd+D` (marks word, stays Normal) → press again to add more →
   `mi` (left) / `ma` (right) to start editing all cursors → `Esc`.
   `mcc` cancels all cursors.

CRITICAL mistakes to avoid (each was hit and debugged):
- Do NOT map `Cmd+D` to `vscode-neovim.send args:"i"`. That auto-enters Insert
  mode and breaks the flow — this is the most common cause of "Cmd+D jumps into
  Insert".
- Do NOT map `Cmd+D` to the plugin's `addSelectionToNextFindMatch()` wrapper. It
  internally does `<ESC>a` (throws you into Insert) AND does NOT feed the
  plugin's cursor STATE, so `mi`/`ma` silently do nothing.
- `mc` is an OPERATOR, not a standalone command. Use `mciw`, `mcap`, `mc$`, or
  select in Visual mode then press `mc`.
- VS Code native `Cmd+D` multi-cursor is INCOMPATIBLE with the plugin's
  `mi`/`ma` (different cursor systems). Pick one system.

## Trap 3 — Plugin API drift
- `leap.nvim`: `add_default_mappings()` / `set_default_mappings()` /
  `create_default_mappings()` are all DEPRECATED (print warnings). Map the
  `<Plug>` interface directly: `s`→`<Plug>(leap-forward)`,
  `S`→`<Plug>(leap-backward)`, `gs`→`<Plug>(leap-from-window)`.
  The repo moved to `https://codeberg.org/andyg/leap.nvim` — use the `url` field
  in lazy.nvim, not `"ggandor/leap.nvim"`.
- `nvim-treesitter` (2025 rewrite): the old `require("nvim-treesitter.configs")`
  module is GONE. Core only installs parsers; `highlight` was removed (VS Code
  handles it) and `textobjects` split into a separate plugin. Installing parsers
  via lazy `build = ":TSUpdate"` is unreliable when `config` runs afterwards.
  RECOMMENDATION: omit treesitter entirely. Built-in Vim text objects
  (`i(`, `a"`, `iw`, `it`) cover 99% of cases and need no parser. If
  treesitter textobjects are wanted, trigger `:TSUpdate` on `LazyDone`.
- `flash.nvim`: `char` mode is on by default (enhances `f`/`t`/`;`/`,`). Set
  `jump_labels = true` for two-character labels.

## Verification
After writing init.lua, load-check with `nvim --headless -c 'qa' 2>&1` and grep
for `Error in|traceback|not found`. The `vscode` module is absent in headless
mode, so a plugin gated by `cond = not not vim.g.vscode` will not load there.
To force-check it, run `nvim --cmd 'let g:vscode=1' --headless ...` — the
`module 'vscode' not found` line in that test is a FALSE ALARM (the `vscode`
module is provided by the extension at runtime); ignore it. Confirm plugin
mappings are registered with `:Lazy load <plugin>` then
`:lua print(vim.fn.maparg('mc','n'))`.

## Files bundled with this skill
- `references/init.lua` — full known-good init.lua (5 plugins, fold + multi-cursor bridges)
- `references/keybindings.json` — VS Code keybindings with the correct `Cmd+D` entry and fold-friendly `j`/`k`
