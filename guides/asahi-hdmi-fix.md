# Fix for Asahi Linux HDMI Boot Freeze Issue

## Problem
When booting Asahi Linux with an external HDMI monitor connected, the system freezes during initialization due to unstable HPD (Hot Plug Detect) signals from the DP-to-HDMI adapter.

## Solution Overview
Blacklist the `apple_dcp` module during boot, then load it with a delay after the system has stabilized. This prevents the freeze caused by the flaky HDMI connection during early boot.

## Step-by-Step Fix

### 1. Disable HDMI at Boot via GRUB
Edit the GRUB configuration:
```bash
sudo nvim /etc/default/grub
```

Modify the `GRUB_CMDLINE_LINUX_DEFAULT` line to add `video=HDMI-A-1:d`:
```bash
GRUB_CMDLINE_LINUX_DEFAULT="loglevel=3 quiet video=HDMI-A-1:d"
```

Apply the changes:
```bash
sudo grub-mkconfig -o /boot/grub/grub.cfg
```

### 2. Blacklist the apple_dcp Module
Create a blacklist file:
```bash
sudo nvim /etc/modprobe.d/blacklist-apple-dcp.conf
```

Add this line:
```
blacklist apple_dcp
```

### 3. Remove apple_dcp from initramfs (if present)
Edit the mkinitcpio configuration:
```bash
sudo nvim /etc/mkinitcpio.conf
```

Find the `MODULES=()` line and ensure `apple_dcp` is NOT listed. If it is, remove it.

Rebuild initramfs:
```bash
sudo mkinitcpio -P
```

### 4. Create Delayed Module Load Script
Create the script:
```bash
sudo nvim /usr/local/bin/load-dcp-delayed.sh
```

Add this content:
```bash
#!/bin/bash
sleep 5
modprobe apple_dcp
sleep 3

# Trigger DRM hotplug detection
for card in /sys/class/drm/card*/status; do
    echo detect > "$card" 2>/dev/null || true
done

echo "DCP loaded, hotplug triggered"
```

Make it executable:
```bash
sudo chmod +x /usr/local/bin/load-dcp-delayed.sh
```

### 5. Create systemd Service
Create the service file:
```bash
sudo nvim /etc/systemd/system/load-apple-dcp.service
```

Add this content:
```ini
[Unit]
Description=Load Apple DCP with delay
DefaultDependencies=no
After=sysinit.target

[Service]
Type=oneshot
ExecStart=/usr/local/bin/load-dcp-delayed.sh
RemainAfterExit=yes

[Install]
WantedBy=multi-user.target
```

Enable the service:
```bash
sudo systemctl daemon-reload
sudo systemctl enable load-apple-dcp.service
```

### 6. Reboot
```bash
sudo reboot
```

## Verification
After boot, verify everything is working:

```bash
# Check if the module loaded
lsmod | grep apple_dcp

# Check service status
systemctl status load-apple-dcp.service

# Check if HDMI is detected
hyprctl monitors
cat /sys/class/drm/card0-HDMI-A-1/status
```

## What This Does
1. **GRUB parameter**: Disables HDMI output at the kernel level during boot
2. **Blacklist**: Prevents `apple_dcp` from loading automatically during early boot
3. **Delayed script**: Waits 5 seconds after system init, loads the module, then triggers hotplug detection
4. **systemd service**: Automates the delayed loading process on every boot

## Root Cause
The issue is caused by unstable HPD signals from DP-to-HDMI adapters during early boot initialization. The HDMI connection briefly drops (~10 seconds after initial detection), causing the DCP driver to hang while Hyprland is starting. By delaying the module load until after the system stabilizes, the HPD signal remains stable.
