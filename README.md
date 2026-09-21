# Mac Fan Control for Omarchy

A native Omarchy bar widget for Intel MacBooks using the Linux `applesmc`
driver and `mbpfan`.

It displays CPU temperature and fan RPM and offers three modes:

- **Auto** restores the original `/etc/mbpfan.conf`.
- **Cool** applies an earlier, configurable fan curve (45/55/70°C by default).
- **Maximum** holds every detected Apple SMC fan at its reported maximum RPM.

Maximum mode is deliberately not enabled across reboot. The installed mbpfan
service remains enabled and resumes automatic thermal control on the next boot.

## Requirements

- Omarchy 4 or newer
- An Intel Mac with the `applesmc` and `coretemp` kernel modules
- `mbpfan`, `jq`, `systemd`, and `pkexec`

On Omarchy/Arch, install mbpfan first if needed:

```bash
omarchy pkg aur add mbpfan
```

## Install

```bash
omarchy plugin add https://github.com/pedromst/omarchy-mac-fan-control.git --enable
cd ~/.config/omarchy/plugins/pedromst.mac-fan-control
sudo ./install.sh
```

The second command installs a small, root-owned helper, systemd unit, and a
strict Polkit rule. The rule allows the active local user to run only this
argument-validating helper without repeated password prompts; it does not grant
passwordless access to other administrative commands.

## Use

- Left click: open the control panel.
- Right click: toggle between Auto and Maximum.
- Middle click: refresh sensor readings.
- Plugin settings: change the refresh rate and edit the Cool curve. The bar
  always uses a clean, icon-only appearance; RPM remains visible in the panel.

CLI and IPC are also available:

```bash
~/.config/omarchy/plugins/pedromst.mac-fan-control/bin/mac-fan-control status
~/.config/omarchy/plugins/pedromst.mac-fan-control/bin/mac-fan-control cool 45 55 70
omarchy-shell pedromst.mac-fan-control status
```

## Safety

The helper only accepts the documented modes and enforces conservative bounds
for a custom curve (`LOW < HIGH < MAX`, with limits no warmer than mbpfan's
stock 55/62/80°C curve). Passwordless Polkit access is granted only to the
specific local account that runs the installer. The helper backs up the
original mbpfan configuration before changing it. Uninstalling restores that
backup and starts mbpfan again:

```bash
sudo ./uninstall.sh
omarchy plugin remove pedromst.mac-fan-control
```

Fan control can reduce temperature, but it cannot repair display flex-cable,
panel, GPU, or logic-board damage. Back up important data and have recurring
display artifacts diagnosed.
