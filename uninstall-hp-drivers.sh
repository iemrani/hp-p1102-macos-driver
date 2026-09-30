#!/bin/bash
# Removes everything installed by HP Printer Drivers 5.1.1 (original or patched).
# Run in Terminal: sudo bash uninstall-hp-drivers.sh
set -uo pipefail

PKG="com.apple.pkg.HewlettPackardPrinterDrivers"

if [ "$(id -u)" -ne 0 ]; then
    echo "Run with sudo: sudo bash $0"
    exit 1
fi
if ! pkgutil --pkg-info "$PKG" >/dev/null 2>&1; then
    echo "$PKG is not installed. Nothing to do."
    exit 0
fi

# Printer queues that use a driver from this package
for q in $(lpstat -e 2>/dev/null); do
    ppd="/etc/cups/ppd/$q.ppd"
    if [ -f "$ppd" ] && grep -q "/Library/Printers/hp/" "$ppd"; then
        echo "Removing printer queue: $q"
        lpadmin -x "$q"
    fi
done

# Installed files only (shared parent folders such as /Library/Printers stay)
echo "Removing installed files..."
pkgutil --only-files --files "$PKG" | while IFS= read -r f; do
    rm -f "/$f"
done

# Folders that belong only to this package
rm -rf /Library/Printers/hp \
    "/Library/Image Capture/Devices/HP M1130_M1210 Scanner.app" \
    "/Library/Image Capture/Devices/HP Scanner 3.app" \
    "/Library/Image Capture/Devices/HPScanner.app" \
    /Library/Extensions/hp_io_enabler_compound.kext

pkgutil --forget "$PKG"
echo "HP printer drivers removed."
