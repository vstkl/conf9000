#!/usr/bin/bash
BROWSER=firefox
alias torstart="sudo systemctl start --now qbittorrent-nox.service &&  sudo systemctl start --now jackett.service && $BROWSER http://localhost:8080/ "
alias torquit='sudo systemctl stop --now qbittorrent-nox.service &&  sudo systemctl stop --now jackett.service'
