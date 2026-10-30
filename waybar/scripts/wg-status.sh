#!/bin/bash

IFACE="tailscale0"

if ip link show tailscale0 >/dev/null 1>&0 && ip addr show tailscale0 | grep -q "inet "; then
    echo '{"text":"󰒃","class":"connected","tooltip":"WireGuard connected"}'
else
    echo '{"text":"󰒃","class":"disconnected","tooltip":"WireGuard disconnected"}'
fi
