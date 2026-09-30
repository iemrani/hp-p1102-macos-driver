#!/bin/bash
# Builds an HP printer driver installer that macOS 16 and later will accept.
# Source: Apple's official "HP Printer Drivers 5.1.1" package (2021).
# The only change is the maximum macOS version in the installer's Distribution file.
# No driver file is modified.
set -euo pipefail

URL="https://updates.cdn-apple.com/2021/macos/071-46903-20211101-0BD2764A-901C-41BA-9573-C17B8FDC4D90/HewlettPackardPrinterDrivers.dmg"
SHA256="523836b630431bc39b0170a17099099d6f821ef62ff29e6ec64ebb69b9954133"
OUT="$PWD/HewlettPackardPrinterDrivers-patched.pkg"
WORK="$(mktemp -d)"

cleanup() {
    hdiutil detach "$WORK/mnt" -quiet 2>/dev/null || true
    rm -rf "$WORK"
}
trap cleanup EXIT

echo "1/5 Downloading HP Printer Drivers 5.1.1 from Apple (about 560 MB)..."
curl -fL -o "$WORK/HP.dmg" "$URL"

echo "2/5 Verifying SHA-256 checksum..."
echo "$SHA256  $WORK/HP.dmg" | shasum -a 256 -c -

echo "3/5 Extracting the package and checking Apple's signature..."
hdiutil attach "$WORK/HP.dmg" -nobrowse -readonly -mountpoint "$WORK/mnt" -quiet
cp "$WORK/mnt/HewlettPackardPrinterDrivers.pkg" "$WORK/original.pkg"
hdiutil detach "$WORK/mnt" -quiet
if ! pkgutil --check-signature "$WORK/original.pkg" | grep -q "signed Apple Software"; then
    echo "Error: package is not signed by Apple. Stopping."
    exit 1
fi

echo "4/5 Raising the macOS version limit from 15.0 to 99.0..."
pkgutil --expand "$WORK/original.pkg" "$WORK/expanded"
sed -i '' "s/system.version.ProductVersion, '15.0'/system.version.ProductVersion, '99.0'/" "$WORK/expanded/Distribution"
if ! grep -q "system.version.ProductVersion, '99.0'" "$WORK/expanded/Distribution"; then
    echo "Error: version check not found in Distribution. Stopping."
    exit 1
fi

echo "5/5 Rebuilding the installer..."
pkgutil --flatten "$WORK/expanded" "$OUT"

echo "Done: $OUT"
