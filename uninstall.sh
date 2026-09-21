#!/bin/bash
set -euo pipefail

[[ $(id -u) -eq 0 ]] || { echo "Run this uninstaller with sudo." >&2; exit 1; }

systemctl stop omarchy-mac-fan-max.service 2>/dev/null || true
if [[ -f /var/lib/omarchy-mac-fan-control/mbpfan.conf.original ]]; then
  install -m 0644 /var/lib/omarchy-mac-fan-control/mbpfan.conf.original /etc/mbpfan.conf
fi
systemctl enable --now mbpfan.service
systemctl restart mbpfan.service
rm -f /etc/systemd/system/omarchy-mac-fan-max.service
rm -f /usr/local/libexec/omarchy-mac-fan-control-helper
rm -f /etc/polkit-1/rules.d/49-omarchy-mac-fan-control.rules
systemctl daemon-reload

echo "Mac Fan Control system helper removed; mbpfan automatic control restored."
