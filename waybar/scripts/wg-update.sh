#!/bin/bash

IFACE="tailscale0"

if ip link show tailscale0 >/dev/null 1>&0 && ip addr show tailscale0 | grep -q "inet "; then
	tailscale down
else
	tailscale up --accept-routes
fi
