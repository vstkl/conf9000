# Terminal & editor

## kitty (`kitty/kitty.conf`, 8 settings, tracked)
background_opacity 0.81 · tab_bar_style slant · detect_urls · copy_on_select · hide_window_decorations · shell_integration enabled · term xterm-kitty · `enabled_layouts horizontal` (only one layout ⇒ splits always side-by-side). No font/theme set (kitty defaults). `$term` in all WMs.

## tmux (`tmux/tmux.conf`, tracked; `tmux/plugins/tpm` = git submodule, `.gitmodules`)
- prefix **C-Space** (`:4-6`), mouse on, truecolor override, base-index 1, renumber-windows.
- `prefix h/j/k/l` select pane; `M-arrows` pane (no prefix); `S-Left/Right`, `M-H/M-L` window prev/next.
- vi copy mode: v begin-selection, C-v rectangle, y copy.
- `"` / `%` split in current path.
- Plugins (`:36-40`): tpm, tmux-sensible, vim-tmux-navigator, tmux-yank, base16-tmux (`@colors-base16 'ayu-dark'`). `run ~/.config/tmux/plugins/tpm/tpm` (`:42`) — needs `git submodule update --init` (recreate-environment.sh:238 does it). Plugins install with `prefix + I`.
- Note: vim-tmux-navigator also binds C-h/j/k/l.
- **Shortcuts: [tmux/SHORTCUTS.md](../../tmux/SHORTCUTS.md)** (2026-10-30 nvim tuning: `prefix ?` menu, `prefix F1` sheet popup, `|`/`-` splits, `H/J/K/L` resize, `Tab` last window; nvim side of the navigator in `nvim/lua/plugins/tmux.lua`).

## nvim (`nvim/`, tracked) — LazyVim distro
- `init.lua`: bootstraps lazy.nvim into `stdpath("data")/lazy`, `require("config.keymaps")` **before** lazy setup, `lazy.setup({LazyVim + import "plugins"})`, then `require("config.options")`.
- `lazy.lua` (repo root of nvim/): **unused** (spec with checker/perf/ui opts; nothing requires it).
- `lazyvim.json`: extras = copilot-chat, dap core/nlua, lang clangd/cmake/git/java/json/markdown/php/python/rust/sql/toml/typescript/yaml, lsp neoconf/none-ls, ui dashboard-nvim, util gitui.
- `lazy-lock.json` at `nvim/lazy-lock.json` (recreate-environment.sh:255 message wrongly says `lua/lazy-lock.json`).
- `lua/config/keymaps.lua`: leader Space; `<C-~>`/`<C-_>` buffer next/prev; `<leader>n` NvimTreeToggle (nvim-tree not installed → error); LSP `<leader>ca/gd/gi/gr/gD`; `<leader>gx` DiffviewFileHistory.
- `lua/config/options.lua`: number+relative, wrap, tab 2/expandtab (comments say 4), no swap/backup, undofile in `~/.local/share/nvim/undodir`, hlsearch off, guifont FiraCode NF, winborder single, scrolloff 5, updatetime 50, textwidth 200.
- `lua/plugins/base.lua`: LazyVim colorscheme = `$BASE16_THEME` (unset ⇒ LazyVim default), tinted-vim, lazydev, edgy, snacks, blink.cmp (preset enter), **esp32.nvim** (build_dir build.clang), lspconfig+mason, fzf-lua, dap-ui, toggleterm (`<leader>tt`), persistence (`<leader>q*`), render-markdown (`<leader>um`), image.nvim (kitty backend, magick_rock), jupytext, faster.nvim, copilot.lua.
- `lua/plugins/git.lua`: diffview (`<leader>gv/gh/gB`), gitsigns (`<leader>gu/gn/gN/gp/gs/gr` — `gr` collides with keymaps.lua LSP references), fugitive, octo, gitlinker (`<leader>go`), pipeline (`<leader>ga`), linediff.
- `lua/plugins/ui.lua`: empty.
- `nvim/undodir/` (11 files, tracked!): undo history of personal files (`%home%m%...`) — contains file contents; see SENSITIVE.md. Not used by config (options point to ~/.local/share).

## yazi (`yazi/`, untracked)
- `yazi.toml`: ratio 1:4:3, natural sort, show_hidden; openers: folder→`hyprctl dispatch exec … nemo` (Hyprland-only, nemo not installed), nvim, lazygit, codium, kitty; doc→zathura/libreoffice; image→qimgv/krita/satty; video/audio→mpv. Git fetchers registered.
- `init.lua`: full-border (rounded), git, zoxide (update_db), session (sync_yanked).
- `keymap.toml`: C-s shell, J/K half-page, `f g` rg content (fr plugin), `f n` fzf, `s` jump-to-char, `S` fd search, `T` toggle preview, `c a` compress, `y` also puts file:// URIs on wl-clipboard, `g d/v/p/s/D/o/e` → Czech dirs `~/Stažené ~/Videa ~/Obrázky ~/Dokumenty ~/obsidian ~/Projekty` (conflict with English XDG dirs, theming.md#xdg).
- `package.toml` pins plugins (full-border, compress, smart-filter, git, toggle-pane, fr, jump-to-char) + flavor catppuccin-macchiato; `theme.toml` uses local flavor `theme-dark`.
- Deps: zoxide, lazygit not in `packages`.
