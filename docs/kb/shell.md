# Shell (bash)

## bashrc → ~/.bashrc (symlink via recreate-environment.sh:171)
Load order (line numbers in `bashrc`):
1. `:6` return if non-interactive.
2. `:8-12` aliases `ls` (color), `ll` (`ls -lhrsBA --classify=always --sort=time`, time-style `+%M` = minutes only), `llo`, `grep`.
3. `:14-15` `AIRGEDDON_*` (not exported).
4. `:17` `SSH_AUTH_SOCK=$XDG_RUNTIME_DIR/ssh-agent.socket` (expects systemd user ssh-agent.service from guides/ssh-agent.md; unit not in repo). Live ~/.bashrc additionally overrides to `$HOME/.bitwarden-ssh-agent.sock` (not in repo).
5. `:18` `IDF_TOOLS_PATH=/opt/esp/idf/v5.1/` (live bashrc comments it out; superseded by esp-ctx.sh).
6. `:23` `eval "$(fzf --bash)"` (fzf keybinds+completion #1).
7. `:25` `MANPAGER='nvim +Man!'`; `:26` `source /usr/share/nvm/init-nvm.sh` (pkg `nvm`).
8. `:31` `OPENSCADPATH=/usr/share/openscad/libraries`.
9. `:35-36` `GEM_HOME=$(gem env user_gemhome)` (needs ruby; slow), PATH += `$GEM_HOME/bin:/home/m/.cargo/bin:/home/m/.local/bin` (hardcoded /home/m, appended not prepended).
10. `:38-48` `for SCRIPT in $(ls ~/.config/scripts)`: `source` every non-directory entry, alphabetical (`ls` collation). Unquoted → filenames with spaces break. Sources `.ac`, `.bash`, `.sh` alike.
11. `:50-73` prompt (batch 1): sources `/usr/share/git/completion/git-prompt.sh` if readable, `GIT_PS1_*` dirty/untracked/stash/upstream/colors; `__prompt()` builds `user@host cwd (git)` + red `✗<exit>` + newline `❯`; prepended to `PROMPT_COMMAND`. Old `PS1='[\u@\h \W]\$ '` removed.
Commented-out: tinty/BASE16_THEME (`:21,24,28-29,33`).

## scripts/ (all sourced into every interactive shell, in this order)
| file | defines | side effects / notes |
|---|---|---|
| `alias.sh` | aliases `myge` (pack GNOME ext from `/home/m/code/tlp-switcher2`), `lsser` (list serial ttys), `gitlog`, `less=less -R`, `buds`/`mouse` (bluetoothctl connect hardcoded MACs, then write `~/.config/states/*_status` — dir doesn't exist), `unwrap`, `page=nvim -R` | uncommitted change: buds MAC |
| `archive/` | dir, skipped. Holds `idf.sh`, `idf2.sh` (identical to root copies; live machine only has archive copies) | |
| `audio.bash` | alias `audio` → pactl tunnel sink to `192.168.0.136:4656` (see guides/network-audio.md) | LAN IP hardcoded |
| `backup.sh` | nothing (fully commented rsync sketch) | |
| `completion-cloudflare.sh` | `_warp-cli` completion, `complete … warp-cli` | 7.3k lines; near-dup of `warp.ac` |
| `completion-fzf.sh` | fzf key-bindings.bash + completion (`__fzf_*`, Ctrl-T/Ctrl-R/Alt-C) | fzf load #2 |
| `esp-ctx.sh` | `esp` command + `_esp_*` helpers + completion. ESP-IDF version manager on btrfs subvols under `/opt/esp` (`idf/<tag>`, shared `tools`, `.snapshots`); cfg `~/.config/esp-ctx/default`; per-project `.esp-idf-version`. Subcmds: use/off/ls/default/install/snap/rollback/rm/pin/setup/`v*` | defines only; untracked new file. `esp setup` uses sudo, creates group `esp` |
| `fzf.ac` | fzf key-bindings again (newer upstream rev) | fzf load #3 |
| `idf.sh` | sets `IDF_TOOLS_PATH=/opt/esp/idf/v6.0`, `IOT_SOLUTION_PATH`; alias `idf` → `. $IDF_TOOLS_PATH/export.sh` | `[ -n $IDF_TOOLS_PATH ]` unquoted ⇒ always true; overrides bashrc:19; conflicts with esp-ctx (`IDF_TOOLS_PATH=/opt/esp/tools`) |
| `idf2.sh` | nothing (commented) | |
| `paint.sh` | `paint()`; **calls `paint $COLOR` at source time** → writes `~/.config/color.scheme`, runs `tinty apply` | tinty not installed → error every shell; color.scheme is empty so arg empty |
| `setup_venv.bash` | `setup_venv()` (python venv `env/`, greps imports into requirements.txt, pip install) + redundant alias | |
| `since.sh` | `since()` — prints d/m/y since hardcoded epoch 1748222226 | debug echos; math wrong for negative days |
| `spotify-player.ac` | `_spotify_player` completion | |
| `torrent.sh` | `BROWSER=firefox` (global var!), aliases `torstart`/`torquit` (sudo systemctl qbittorrent-nox + jackett) | leaks `BROWSER` into env |
| `warp.ac` | `_warp-cli` completion (dup) | |
| `wps-wifite-loop.sh` | alias `wps-loop` (sudo wifite WPS attack loop, airmon-ng) | |

Startup cost: ~18k lines sourced per shell (two 250 KB warp completions, three fzf integrations, `gem env`, nvm init).

## Other shell-adjacent
- `kitty/kitty.conf`: `shell_integration enabled`.
- `tmux/tmux.conf`: prefix C-Space (terminal-editor.md).
- after-install.sh:32-37 appends `eval "$(fzf --bash)"` to ~/.bashrc (would write through the symlink into repo `bashrc`).
