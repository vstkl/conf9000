# tmux shortcuts

Config: `~/.config/tmux/tmux.conf` (repo `tmux/tmux.conf`).
**Prefix = `C-Space`** (written `P` below). `P C-Space` sends a literal C-Space.
**Help:** `P ?` opens the helper menu, `P F1` shows this file in a popup.

Keys marked *custom* come from this config; the others are tmux defaults or plugins.

## No prefix needed

| key | action | source |
|---|---|---|
| `C-h` `C-j` `C-k` `C-l` | move left/down/up/right: **nvim splits and tmux panes alike** | vim-tmux-navigator |
| `C-\` | previous pane / nvim split | vim-tmux-navigator |
| `M-Left/Right/Up/Down` | select pane | custom |
| `S-Left` / `S-Right` | previous / next window | custom |
| `M-H` / `M-L` (Alt+Shift+h/l) | previous / next window | custom |
| mouse | click pane/window, drag border to resize, wheel = scroll (enters copy mode) | `mouse on` |

`C-l` no longer clears the shell screen: use `P C-l`.

## Panes

| key | action | source |
|---|---|---|
| `P \|` | split side by side (current dir) | custom |
| `P -` | split stacked (current dir) | custom |
| `P %` / `P "` | same as `\|` / `-` (now also keep the current dir) | default, changed |
| `P h/j/k/l` | select pane | custom |
| `P H/J/K/L` | resize by 5 cells, **repeatable** (tap again without prefix) | custom |
| `P z` | zoom / unzoom pane | default |
| `P q` | show pane numbers (press a number to jump) | default |
| `P o` / `P ;` | next pane / last pane | default |
| `P {` / `P }` | swap pane with previous / next | default |
| `P Space` | cycle layouts | default |
| `P !` | break pane into its own window | default |
| `P x` | kill pane (asks) | default |
| `P C-l` | send C-l (clear screen) | custom |

## Windows

| key | action | source |
|---|---|---|
| `P c` | new window | default |
| `P ,` | rename window | default |
| `P 1..9` | go to window N (numbering starts at 1, renumbered on close) | default |
| `P n` / `P p` | next / previous window | default |
| `P C-n` / `P C-p` | next / previous window | tmux-sensible |
| `P Tab` | last window (was `P l`, now used for pane right) | custom |
| `P <` / `P >` | move window left / right (repeatable) | custom |
| `P w` | window/session tree | default |
| `P &` | kill window (asks) | default |

## Sessions

| key | action | source |
|---|---|---|
| `P s` | choose session (tree) | default |
| `P $` | rename session | default |
| `P (` / `P )` | previous / next session | default |
| `P d` | detach | default |
| `P :new -s name` | new session | default |

`P L` (last session) is now resize-right; use `P (`/`P )` or `P s`.

## Copy mode (vi keys, like nvim)

| key | action | source |
|---|---|---|
| `P v` or `P [` | enter copy mode | custom / default |
| `h j k l w b e 0 $ gg G` `C-u` `C-d` | move | default (vi) |
| `/` `?` `n` `N` | search | default (vi) |
| `v` | start selection | custom |
| `V` | select line | custom |
| `C-v` | toggle rectangle (block) selection | custom |
| `y` | yank to tmux buffer + system clipboard and exit | tmux-yank (wl-copy) / OSC 52 |
| `Y` | yank and paste it at the prompt (tmux-yank "put") | tmux-yank |
| `Esc` | clear selection; `q` leaves copy mode | default |
| `P ]` | paste last buffer | default |
| `P =` | choose buffer to paste | default |

## Config, plugins, help

| key | action | source |
|---|---|---|
| `P r` | reload tmux.conf | custom |
| `P R` | reload tmux.conf | tmux-sensible |
| `P I` | install plugins | tpm |
| `P U` | update plugins | tpm |
| `P M-u` | remove plugins not in the config | tpm |
| `P ?` | **helper menu** (tmux's own key list = item `k` in the menu) | custom |
| `P F1` | this cheat sheet in a popup (glow → bat → less) | custom |
| `P /` | describe one key | default |
| `P :` | command prompt | default |
| `P t` | clock | default |

## Settings that matter for nvim

- `escape-time 10`: no delay after `Esc`.
- `focus-events on`: nvim gets `FocusGained` (autoread, tinty theme reload).
- `default-terminal tmux-256color` plus `terminal-features` RGB/usstyle for kitty: true color, undercurl and colored underlines.
- `set-clipboard on` (OSC 52) and tmux-yank: yanks reach the system clipboard.
- `allow-passthrough on`: image.nvim (kitty graphics) works inside tmux.
- `history-limit 50000`, `mouse on`, windows/panes start at 1.
- nvim side of the navigator: `nvim/lua/plugins/tmux.lua` (christoomey/vim-tmux-navigator).
  It replaces LazyVim's `C-h/j/k/l` window maps with versions that also cross into tmux.
- Colors: base16 from tinty (`tmux-colors-file.conf`), nothing is hardcoded.

First run on a new machine: `git submodule update --init` (tpm), then `P I`.
