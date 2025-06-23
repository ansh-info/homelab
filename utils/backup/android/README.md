# Android Backup Script

This script allows you to back up all files from your Android device's internal storage (`/sdcard`) to your local machine using ADB (Android Debug Bridge). It also provides logs for successful and failed file transfers.

## Prerequisites

### 1. Enable Developer Options and USB Debugging on your Android Device

- Go to **Settings > About Phone**
- Tap **Build number** 7 times to unlock Developer Options
- Go back to **Settings > System > Developer Options**
- Enable **USB Debugging**

### 2. Connect Your Device to the PC

- Use a USB cable to connect your Android device to your computer
- Allow the USB debugging prompt on your device when it appears

---

## Installation

### 3. Install ADB and `scrcpy`

You need ADB to communicate with your device and `scrcpy` to mirror/control your screen (optional but recommended).

#### macOS (with Homebrew)

```bash
brew install scrcpy
brew install --cask android-platform-tools
```

#### Ubuntu / Debian

```bash
sudo apt update
sudo apt install android-tools-adb scrcpy
```

#### Windows

1. Install [ADB and Fastboot](https://developer.android.com/tools/releases/platform-tools) or use [Chocolatey](https://chocolatey.org/) (if installed):

   ```bash
   choco install adb scrcpy
   ```

2. Ensure `adb` is in your PATH.

## Usage

### 1. Start `scrcpy` (optional)

Run in a separate terminal to visually confirm the device is connected:

```bash
scrcpy
```

### 2. Run the Backup Script

```bash
python3 scrpy_android_backup.py
```

This will:

- Recursively list files in `/sdcard`
- Pull each file to `~/Downloads/AndroidBackup`
- Save logs in:

  - `pull_log.txt`: All file statuses (OK/FAIL)
  - `errors.txt`: Details of failed pulls

## Manual ADB Pull (Alternative)

You can also manually pull all contents of the `/sdcard` directory:

```bash
adb pull sdcard/ ~/Downloads/Android
```

Note: This will not provide logging or error tracking.

## Related Tools

- [`scrcpy`](https://github.com/Genymobile/scrcpy): Android screen mirroring via USB or TCP
- [ADB Documentation](https://developer.android.com/studio/command-line/adb)

## Troubleshooting

- If `adb devices` shows **unauthorized**, unlock your phone and accept the USB debugging prompt
- If `adb` is not found, verify it is installed and added to your system's PATH
- If backup fails for certain files, check `errors.txt` for details

```

```
