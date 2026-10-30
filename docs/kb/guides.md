# guides/ (tracked, NOT deployed — excluded in recreate-environment.sh:153)

| file | content |
|---|---|
| `README.md` | "config for dummies" intro (@vstkl) |
| `ssh-agent.md` | systemd **user** `ssh-agent.service` with `SSH_AUTH_SOCK=%t/ssh-agent.socket` — matches `bashrc:18`; unit itself not in repo (no `systemd/` dir) |
| `network-audio.md` | PulseAudio TCP: server `module-native-protocol-tcp port=4656`, client `module-tunnel-sink` — used by `scripts/audio.bash` |
| `package-proxy.md` | share `/var/cache/pacman/pkg` via `python -m http.server 8000`; client uses it as a pacman mirror |
| `generate-self-signed-ssl.sh` | Czech-commented, Debian/apt (apache2+openssl) CA + cert under `/home/student/company` — school lab script, not for this machine |
| `generate-tls-asterisk.sh` | Debian: build Asterisk 20 from source + TLS certs for an IP — school lab script |
