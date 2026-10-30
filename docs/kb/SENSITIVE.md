# Sensitive paths — never commit, never copy into test images/VMs, never cat into logs

Values were NOT copied into this KB. Only data *kinds* are listed.

## Critical (secrets / private communications)
| path | tracked | data |
|---|---|---|
| `Signal/` (325 MB) | U | Signal Desktop: encrypted SQL DB (`sql/`), `config.json` holds the DB key, attachments, drafts, IndexedDB/Local Storage |
| `Bitwarden/` (5.6 MB) | U | Electron state: `data.json` (encrypted vault, account/session info), Local Storage, Cache |
| `mozilla/firefox/` (326 MB, 2 profiles `*.default-release`, `*.default`) | U | cookies, saved logins (logins.json/key4.db), history, session, extensions |
| `opencode/service.json` | U | opencode server **password** (plaintext) |
| `pulse/cookie` | U | PulseAudio auth cookie |
| `gh/hosts.yml` | U | GitHub CLI host + username (token currently in keyring, but gh writes `oauth_token` here when keyring absent) |
| `github-copilot/` | U | currently only versions.json; Copilot writes `apps.json`/`hosts.json` OAuth tokens here |
| `waybar/scripts/claude-usage.sh` | U | not a secret itself, but reads `~/.claude/.credentials.json`; cache `/tmp/claude-usage.json` |

## Personal data (privacy, not credentials)
| path | tracked | data |
|---|---|---|
| `nvim/undodir/` | **T** (already in git history) | undo trees = contents of personal files (bashrc, project files, blog post draft, VM xml) |
| `dconf/user` | **T** | GNOME settings incl. virt-manager connection URIs, simple-weather location, clocks/alarms, recent-file-ish app state, shell command history |
| `freerouting/freerouting.json` | U | profile id, email field |
| `wordcraft/recovery/`, `wordcraft/logs/` | U | unsaved document text, logs |
| `evolution/sources/` | U | calendar sources (no accounts currently) |
| `libreoffice/4/user/` | U | recent documents, autocorrect, macros, database |
| `GIMP/3.2/`, `inkscape/`, `OpenSCAD/`, `fstl-app/`, `vlc/`, `wireshark/recent*`, `QtProject.conf`, `kicad/9.0/*.json`(T), `totem/` | mixed | recent files / paths / filters |
| `ibus/bus/` | U | per-machine bus address files |
| `gtk-4.0/servers` | T | GTK bookmarks of network servers (e.g. SMB hosts on LAN) |
| `scripts/alias.sh:5-6` | T | Bluetooth MAC addresses of user devices |
| `scripts/audio.bash` | T | LAN IP of audio server |
| `user-dirs.dirs` | U | harmless, but mode 600 |

## Recommended `.gitignore` (do not apply without user OK)
```gitignore
# app state / secrets
/Bitwarden/
/Signal/
/mozilla/
/gh/
/github-copilot/
/opencode/
/pulse/
/ibus/
/evolution/
/freerouting/
/wordcraft/
/libreoffice/
/GIMP/
/inkscape/
/OpenSCAD/
/fstl-app/
/vlc/
/totem/
/wireshark/
/epiphany/
/goa-1.0/
/libvirt/
/nautilus/
/QtProject.conf
/pavucontrol.ini
# generated / runtime
/nvim/undodir/
/failed-packages.log
/hypr/.initial_startup_done
/waybar/scripts/*.cache
# backups
*.bak
*.bak-*
*.bk
*.broken-*
*.bak.sh
# local tooling
/testenv/images/
```
Also: `git rm -r --cached nvim/undodir` (history still contains it — rewrite only if the user wants). Consider moving `dconf/user` to a `dconf dump` text export (reviewable, filterable).

## For test images (testenv/)
`testenv/sync-exclude.txt` (subagent B) already excludes most state dirs but, as of this survey, NOT: `/wordcraft/`, `/OpenSCAD/`, `/fstl-app/`, `/nvim/undodir/`, `/QtProject.conf`, `/pavucontrol.ini`, `/kicad/` MRU, `/dconf/user` (personal), `/epiphany/ /libvirt/ /nautilus/` (empty). `/testenv/` itself and `/docs/` should be excluded from the dotfile deploy step.
Exclude at minimum every path in the two tables above when syncing the repo into a VM/chroot; prefer an allowlist (`sway scroll hypr niri waybar mako fuzzel rofi kitty tmux nvim yazi gtk-* lxqt scripts bashrc mimeapps.list user-dirs.* packages recreate-environment.sh refind`).
