# Mac Fan Control for Omarchy

A native Omarchy bar widget for supported Intel Macs using the Linux
`applesmc` driver and `mbpfan`.

It displays CPU temperature and fan RPM and offers three modes:

- **Auto** restores the `/etc/mbpfan.conf` saved when the system helper was
  installed.
- **Cool** applies an earlier, configurable fan curve (45/55/70°C by default).
- **Maximum** holds every detected Apple SMC fan at its reported maximum RPM.

The bar can optionally show the live CPU package temperature beside the fan
icon, like the battery percentage indicator. It is hidden by default and can be
switched on from the plugin panel, where Celsius or Fahrenheit can also be
selected. The fan icon turns red only while Maximum mode is active.

Maximum mode is deliberately not enabled across reboot. The installed `mbpfan`
service remains enabled and resumes automatic thermal control on the next boot.

## Requirements

- Omarchy 4 or newer
- An Intel Mac with working `applesmc` and `coretemp` kernel modules
- `mbpfan`, `jq`, `systemd`, and `pkexec`

This plugin does not support Apple Silicon or an Intel Mac on which the
`applesmc` fan interface is unavailable.

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

The second command saves the current `mbpfan` configuration and installs a
small root-owned helper, a systemd unit, and a narrow Polkit rule. The rule
allows only the active local user who ran the installer to invoke that fixed,
argument-validating helper without repeated password prompts. It does not grant
passwordless access to other administrative commands.

## Update

Return to automatic control before updating, then refresh both the plugin code
and its root-owned system helper:

```bash
~/.config/omarchy/plugins/pedromst.mac-fan-control/bin/mac-fan-control auto
omarchy plugin update pedromst.mac-fan-control
cd ~/.config/omarchy/plugins/pedromst.mac-fan-control
sudo ./install.sh
```

The plugin settings and bar placement are preserved.

`omarchy plugin update` updates the user-owned plugin files only. When a release
changes the root-owned helper or systemd unit, rerun `sudo ./install.sh` as shown
above; Omarchy deliberately does not execute privileged plugin code during a
Git update.

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

## Safety and limitations

The user-facing helper accepts only the documented modes and enforces a
conservative ceiling for a custom curve: `LOW < HIGH < MAX`, with maximum
accepted values of 55/62/80°C. Passwordless Polkit access is granted only to
the specific local account that runs the installer. Mode transitions fall back
to automatic `mbpfan` control if the requested controller cannot start.

Earlier fan ramps can reduce CPU temperature, but they also increase noise and
may increase fan wear. Maximum mode is intended for short, supervised use.

Uninstalling restores the saved `mbpfan` configuration and verifies that
automatic control starts before removing the privileged helper:

```bash
sudo ./uninstall.sh
omarchy plugin remove pedromst.mac-fan-control
```

Fan control can reduce CPU temperature. It cannot guarantee lower temperatures
for every component, prevent hardware failure, or repair display flex-cable,
panel, GPU, or logic-board damage. Back up important data and have recurring
display artifacts diagnosed.
