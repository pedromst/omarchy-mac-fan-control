#!/bin/bash
set -euo pipefail

[[ $(id -u) -eq 0 ]] || { echo "Run this installer with sudo." >&2; exit 1; }
plugin_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)

command -v mbpfan >/dev/null || { echo "mbpfan is required." >&2; exit 1; }
compgen -G '/sys/devices/platform/applesmc.*' >/dev/null || { echo "Apple SMC was not detected." >&2; exit 1; }

install -d -m 0755 /usr/local/libexec
install -m 0755 "$plugin_dir/system/omarchy-mac-fan-control-helper" /usr/local/libexec/omarchy-mac-fan-control-helper
install -m 0644 "$plugin_dir/system/omarchy-mac-fan-max.service" /etc/systemd/system/omarchy-mac-fan-max.service
install -m 0644 "$plugin_dir/system/49-omarchy-mac-fan-control.rules" /etc/polkit-1/rules.d/49-omarchy-mac-fan-control.rules
systemctl daemon-reload
systemctl enable --now mbpfan.service

echo "Mac Fan Control system helper and restricted Polkit rule installed."
