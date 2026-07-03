#!/bin/bash

set -e

if [ "$EUID" -ne 0 ]; then
  echo "Please run as root"
  exit 1
fi

echo "Configuring hugepages (1024 x 2MB) in /etc/default/grub..."
if [ -f /etc/default/grub ]; then
    if ! grep -q "hugepagesz=2M" /etc/default/grub; then
        sed -i 's/GRUB_CMDLINE_LINUX_DEFAULT="/GRUB_CMDLINE_LINUX_DEFAULT="default_hugepagesz=2M hugepagesz=2M hugepages=1024 /' /etc/default/grub
        if command -v update-grub &> /dev/null; then
            update-grub
        elif command -v grub-mkconfig &> /dev/null; then
            grub-mkconfig -o /boot/grub/grub.cfg
        fi
        echo "Hugepages configured. Please reboot your system for changes to take effect."
    else
        echo "Hugepages already configured in /etc/default/grub"
    fi
else
    echo "Warning: /etc/default/grub not found. Skipping hugepages configuration."
fi

echo "Detecting OS..."
if [ -f /etc/os-release ]; then
    . /etc/os-release
    OS=$ID
else
    echo "Unsupported OS."
    exit 1
fi

echo "Installing DPDK and P4 development tools..."
if [[ "$OS" == "ubuntu" || "$OS" == "debian" ]]; then
    apt-get update
    # DPDK system dependencies
    apt-get install -y meson ninja-build libnuma-dev build-essential python3-pyelftools
    
    # P4 development tools (assuming PPA or standard repo availability, otherwise requires building from source)
    echo "Note: p4c and bmv2 may require adding the p4lang PPA depending on your Ubuntu version."
    # sudo add-apt-repository p4lang/p4-c -y
    apt-get install -y p4c bmv2 || echo "Could not install p4c or bmv2 automatically. Please install from source or AUR/PPA."
elif [[ "$OS" == "cachyos" || "$OS" == "arch" ]]; then
    pacman -Sy --noconfirm meson ninja numactl
    echo "For p4c and bmv2 on Arch-based systems, please use an AUR helper like yay:"
    echo "  yay -S p4c bmv2"
else
    echo "Unsupported OS for automatic dependency installation: $OS"
    exit 1
fi

echo "Dependencies script execution completed."
