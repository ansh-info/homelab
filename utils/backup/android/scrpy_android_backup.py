import os
import subprocess
from pathlib import Path

from tqdm import tqdm

ADB_PATH = "adb"
REMOTE_ROOT = "/sdcard"
LOCAL_ROOT = os.path.expanduser("~/Downloads/AndroidBackup")

log_file = Path(LOCAL_ROOT) / "pull_log.txt"
error_log_file = Path(LOCAL_ROOT) / "errors.txt"


def run_adb_ls(path):
    """Recursively list files on device using adb shell ls -R and filter them."""
    try:
        result = subprocess.run(
            [ADB_PATH, "shell", f"ls -R {path}"],
            capture_output=True,
            text=True,
            check=True,
        )
        lines = result.stdout.splitlines()

        all_paths = []
        current_dir = None
        for line in lines:
            line = line.strip()
            if line.endswith(":"):
                current_dir = line[:-1]
            elif line and current_dir:
                full_path = f"{current_dir}/{line}"
                all_paths.append(full_path)

        return [p for p in all_paths if not p.endswith("/")]
    except subprocess.CalledProcessError as e:
        print(f"[!] Failed to list files: {e.stderr}")
        return []


def pull_file(remote_file, local_file):
    """Attempt to pull a single file via adb."""
    local_file.parent.mkdir(parents=True, exist_ok=True)
    try:
        result = subprocess.run(
            [ADB_PATH, "pull", remote_file, str(local_file)],
            capture_output=True,
            text=True,
        )
        if result.returncode != 0:
            with open(error_log_file, "a") as ef:
                ef.write(f"FAILED: {remote_file} → {local_file}\n")
                ef.write(result.stderr + "\n")
            return False
        return True
    except Exception as e:
        with open(error_log_file, "a") as ef:
            ef.write(f"EXCEPTION: {remote_file} → {local_file}\n{str(e)}\n")
        return False


def main():
    print(f"[+] Scanning all files inside {REMOTE_ROOT}...")
    files = run_adb_ls(REMOTE_ROOT)
    total_files = len(files)
    print(f"[+] Found {total_files} files to copy.")

    Path(LOCAL_ROOT).mkdir(parents=True, exist_ok=True)

    with open(log_file, "w") as lf, tqdm(
        total=total_files, desc="Pulling files", unit="file"
    ) as pbar:
        for remote_file in files:
            relative_path = Path(remote_file).relative_to(REMOTE_ROOT)
            local_path = Path(LOCAL_ROOT) / relative_path

            success = pull_file(remote_file, local_path)
            status = "OK" if success else "FAIL"

            lf.write(f"[{status}] {remote_file} → {local_path}\n")
            lf.flush()  # flush log to disk
            pbar.update(1)
            pbar.refresh()  # <--- force refresh

    print("[✔] Backup completed. Logs saved to:")
    print(f"    {log_file}")
    print(f"    {error_log_file}")


if __name__ == "__main__":
    main()
