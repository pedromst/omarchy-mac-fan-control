#!/bin/bash
set -euo pipefail

[[ $(id -u) -eq 0 ]] || { echo "Run this installer with sudo." >&2; exit 1; }
plugin_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)

command -v mbpfan >/dev/null || { echo "mbpfan is required." >&2; exit 1; }
command -v jq >/dev/null || { echo "jq is required." >&2; exit 1; }
command -v pkexec >/dev/null || { echo "pkexec is required." >&2; exit 1; }
compgen -G '/sys/devices/platform/applesmc.*' >/dev/null || { echo "Apple SMC was not detected." >&2; exit 1; }
[[ -f /etc/mbpfan.conf ]] || { echo "/etc/mbpfan.conf was not found." >&2; exit 1; }

install_user=${SUDO_USER:-}
if [[ -z "$install_user" && ${PKEXEC_UID:-} =~ ^[0-9]+$ ]]; then
  install_user=$(getent passwd "$PKEXEC_UID" | cut -d: -f1)
fi
[[ "$install_user" =~ ^[a-z_][a-z0-9_-]*$ && "$install_user" != root ]] || {
  echo "Could not determine the non-root user installing this plugin." >&2
  exit 1
}

policy_tmp=$(mktemp /run/omarchy-mac-fan-control-policy.XXXXXX)
trap 'rm -f "$policy_tmp"' EXIT
sed "s/__INSTALL_USER__/$install_user/g"   "$plugin_dir/system/49-omarchy-mac-fan-control.rules" >"$policy_tmp"

install -d -m 0755 /usr/local/libexec
install -d -m 0700 /var/lib/omarchy-mac-fan-control
if [[ ! -f /var/lib/omarchy-mac-fan-control/mbpfan.conf.original ]]; then
  install -m 0600 /etc/mbpfan.conf /var/lib/omarchy-mac-fan-control/mbpfan.conf.original
fi
install -m 0755 "$plugin_dir/system/omarchy-mac-fan-control-helper" /usr/local/libexec/omarchy-mac-fan-control-helper
install -m 0644 "$plugin_dir/system/omarchy-mac-fan-max.service" /etc/systemd/system/omarchy-mac-fan-max.service
install -m 0644 "$policy_tmp" /etc/polkit-1/rules.d/49-omarchy-mac-fan-control.rules
systemctl daemon-reload
systemctl enable --now mbpfan.service

echo "Mac Fan Control helper installed for $install_user."
