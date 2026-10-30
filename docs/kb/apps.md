# Other app dirs (one line each). T = tracked, U = untracked. ⚠ = see SENSITIVE.md

| dir | T/U | contents |
|---|---|---|
| `ardour8/` | T | Ardour DAW config, instant.xml, plugin_metadata, sfdb, ui_scripts; session dir `/home/m/music` |
| `corectrl/` | T | corectrl.ini + `profiles/_global_.ccpro` (GPU/CPU power profile) |
| `easyeffects/` | T | output presets `t490*.json`, autoload for output device |
| `kicad/9.0/` | T | KiCad 9 prefs, lib tables, MRU lists of `/home/m/proj/mausring/...` projects |
| `lsp-plugins/` | T | LSP plugins cfg + bookmarks (lowercase /home/m dirs) |
| `neofetch/config.conf` | T | neofetch layout (stock-ish) |
| `ventoy/Ventoy2Disk.ini` | T | Ventoy GUI lang/partition style |
| `lxqt/lxqt.conf` | T | icon_theme=oxygen (for lxqt-policykit) |
| `GIMP/3.2/` | U | GIMP prefs, brushes/palettes, action-history, CrashLog, backups |
| `inkscape/` | U | preferences.xml, cphistory, extension-errors.log |
| `libreoffice/4/user/` | U | LO profile: registrymodifications.xcu (recent docs), autocorr, extensions, database |
| `OpenSCAD/OpenSCAD.conf` | U | prefs + recent files |
| `fstl-app/fstl.conf` | U | STL viewer prefs + recentFiles (/home/m/downloads/...) |
| `freerouting/freerouting.json` | U ⚠ | freerouting prefs incl. profile id/email fields |
| `opencode/service.json` | U ⚠ | opencode service **password** |
| `vlc/` | U | vlcrc, qt interface (recent media) |
| `totem/state.ini` | U | window size |
| `wireshark/` | U | recent files/filters/interfaces |
| `wordcraft/` | U ⚠ | ui.json, logs, `recovery/` (unsaved document text) |
| `pavucontrol.ini` | U | window/tab state |
| `QtProject.conf` | U | Qt file dialog history |
| `pulse/cookie` | U ⚠ | PulseAudio auth cookie |
| `ibus/bus/*` | U ⚠ | ibus D-Bus address/socket info (runtime) |
| `evolution/sources/` | U | birthdays/system-calendar/system-proxy .source (no accounts) |
| `gh/` | U ⚠ | gh CLI config.yml + hosts.yml (username; token not in file → keyring) |
| `github-copilot/versions.json` | U | copilot version stamp (auth file not present but dir is where it lands) |
| `Bitwarden/` | U ⚠⚠ | Electron app state: data.json (encrypted vault), Local Storage, Cache |
| `Signal/` | U ⚠⚠ | Signal Desktop: `sql/` DB, config.json (DB key), attachments, drafts, 325 MB |
| `mozilla/firefox/` | U ⚠⚠ | 2 Firefox profiles (cookies, logins, history), 326 MB |
| `epiphany/ goa-1.0/ libvirt/ nautilus/` | U | empty dirs |
| `docs/` | U | PROGRESS.md + this KB |
| `testenv/` | U | test env scripts + ~550 MB VM images (subagent B) |
