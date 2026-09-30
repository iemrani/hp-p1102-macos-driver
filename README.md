# HP LaserJet P1102 on macOS 26 and 27 (Apple silicon)

HP has no official driver for the LaserJet P1102 on current macOS. This folder
gets HP's last official Mac driver to install and print anyway.

**Tested on:** macOS 27.0, Apple silicon Mac, HP LaserJet Professional P1102 over USB.
It should also work for the P1102w and other P1100-series printers.

**Unofficial.** HP and Apple do not support this. Use it at your own risk.

## Symptoms

- You print, macOS says the job is done, and nothing comes out.
- In Printers & Scanners, the printer uses the driver **"HP LaserJet Series PCL 4/5"**.
- HP's driver installer refuses to run on this macOS version.

## Why it happens

1. **Wrong driver.** The P1102 is a host-based printer: the computer renders the
   page, and the printer only understands HP's own format. macOS falls back to a
   generic PCL driver. The printer can't read PCL, so it drops the job without
   an error.
2. **Blocked installer.** HP's last Mac driver is Apple's "HP Printer Drivers 5.1.1"
   (2021). Its installer contains a version check that rejects any macOS newer than 15.
3. **Intel-only driver.** The driver is built for Intel Macs. Apple silicon Macs
   need Rosetta 2 to run it.

## What is in this repo

| File | What it is |
|---|---|
| `make-patched-pkg.sh` | Builds the patched installer from Apple's official download |
| `uninstall-hp-drivers.sh` | Removes everything the driver installs |

This repo does not host the driver itself. It belongs to HP and Apple.

## What the patch changes

Exactly one line in the installer's `Distribution` file:

```diff
- if (system.compareVersions(system.version.ProductVersion, '15.0') > 0) {
+ if (system.compareVersions(system.version.ProductVersion, '99.0') > 0) {
```

No driver file is modified. Because the installer is rebuilt, it loses Apple's
signature. That is expected, and it is why macOS asks you to confirm before it runs.

## Security checks done

- The Apple download matches its published SHA-256 checksum
  (`523836b6...9954133`, the same value Homebrew's cask uses).
- The original package is signed "Apple Software".
- The installer's pre- and post-install scripts were read in full. They make no
  network connections. They only save and restore printer settings, register
  the queue, and refresh Image Capture.

## Install

### 1. Install Rosetta 2 (Apple silicon only)

```bash
softwareupdate --install-rosetta --agree-to-license
```

### 2. Build the installer

Download this repo (**Code → Download ZIP**), open Terminal in its folder, and run:

```bash
bash make-patched-pkg.sh
```

The script downloads Apple's official package, checks its checksum and signature,
and applies the patch. You only trust Apple's download and a short script you can
read. It needs about 2 GB of free space.

### 3. Install the driver

Double-click `HewlettPackardPrinterDrivers-patched.pkg`. If macOS blocks it, open
**System Settings → Privacy & Security** and click **Open Anyway**.

Or in Terminal:

```bash
sudo installer -pkg HewlettPackardPrinterDrivers-patched.pkg -target /
```

### 4. Set the printer's driver

**New printer:** System Settings → Printers & Scanners → Add Printer. Select the
P1102. Under **Use**, choose **Select Software** and pick
**"HP LaserJet Professional P1100"**.

**Printer already added with the wrong driver:** remove it and add it again as above.
Or switch the driver in Terminal (replace the queue name if yours differs):

```bash
lpadmin -p HP_LaserJet_Professional_P1102 -m Library/Printers/PPDs/Contents/Resources/hp1100.ppd.gz
```

### 5. Print

The P1100 driver has only one paper source, **Manual Feed**. When a job arrives,
the printer waits for paper:

- Push the paper in until the rollers grab it.
- If it still waits, press the **Go** button.

## Troubleshooting

| What you see | What to do |
|---|---|
| Job "completes" but nothing prints | The queue still uses the PCL 4/5 driver. Redo step 4. |
| "Load paper in the manual feed tray and press Go" | Normal with this driver. Push the paper in, or press Go. |
| Printer does nothing, no lights | Check the power switch, the cable at both ends, and use a wall outlet. |
| Installer says it is not supported | You ran the original HP package, not the patched one. |
| Driver installs but jobs fail on Apple silicon | Rosetta is missing. Redo step 1. |

## Uninstall

```bash
sudo bash uninstall-hp-drivers.sh
```

It removes any printer queue that uses this driver, then all installed files,
then the package receipt. Other printers are left alone.

## How long this will work

Apple has said Rosetta 2 stays fully available through macOS 27 and will then be
limited. On Apple silicon, this driver will likely stop working after macOS 27.

## Credits

- Kartones blog: [macOS Sequoia and Tahoe HP LaserJet P1102 drivers](https://blog.kartones.net/post/macos-sequoia-hp-laserjet-p1102-drivers/)
- pavelbinar's gist: [HP LaserJet P1102 Drivers for macOS Sequoia](https://gist.github.com/pavelbinar/e14bb47f98768d83828bdee89a47490e)

The driver belongs to HP and Apple. This folder only changes the installer's version check.
