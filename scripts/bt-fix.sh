#!/usr/bin/env bash
sudo systemctl stop bluetooth
sudo modprobe -r hci_bcm4377
sudo modprobe hci_bcm4377
sudo systemctl start bluetooth
sleep 1
bluetoothctl power on
echo "BT reset. Try connecting now."
