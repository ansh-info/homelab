#!/usr/bin/env python3
"""
Detect and safely remove duplicate files in a directory tree using SHA-256 hashing
"""

import os
import argparse
import hashlib
from pathlib import Path
from collections import defaultdict


def hash_file(path, chunk_size=1024 * 1024):
    """Return SHA-256 hash of file contents."""
    h = hashlib.sha256()
    with open(path, "rb") as f:
        while True:
            chunk = f.read(chunk_size)
            if not chunk:
                break
            h.update(chunk)
    return h.hexdigest()


def files_are_identical(p1, p2, chunk_size=1024 * 1024):
    """
    Extra safety: compare two files byte-by-byte.
    If this returns True, files are guaranteed identical in content.
    """
    with open(p1, "rb") as f1, open(p2, "rb") as f2:
        while True:
            b1 = f1.read(chunk_size)
            b2 = f2.read(chunk_size)
            if not b1 and not b2:
                return True  # reached end of both files
            if b1 != b2:
                return False


def scan_for_duplicates(root_path, show_progress=False):
    """
    scan the directory at root_path recursively for duplicate files.
    """
    root_path = Path(root_path)
    if not root_path.is_dir():
        raise NotADirectoryError(f"{root_path} is not a directory")

    # key: (size, sha256) -> list[path]
    dup_map = defaultdict(list)

    total_files = 0
    total_size = 0

    for dirpath, dirnames, filenames in os.walk(root_path):
        for filename in filenames:
            path = Path(dirpath) / filename
            if not path.is_file():
                continue
            try:
                size = path.stat().st_size
            except OSError:
                continue

            total_files += 1
            total_size += size

            try:
                file_hash = hash_file(path)
            except (OSError, PermissionError) as e:
                if show_progress:
                    print(f"Skipping {path} (error: {e})")
                continue

            key = (size, file_hash)
            dup_map[key].append(path)

            if show_progress and total_files % 500 == 0:
                print(f"Scanned {total_files} files...")

    return dup_map, total_files, total_size


def format_size(num_bytes):
    """
    format byte count into human-readable string.
    """
    for unit in ["B", "KB", "MB", "GB", "TB"]:
        if num_bytes < 1024:
            return f"{num_bytes:.2f} {unit}"
        num_bytes /= 1024
    return f"{num_bytes:.2f} PB"


def plan_deletions(dup_map):
    """
    Decide which files to delete.
    For each group (same size + hash):
      - Keep 1 file (lexicographically smallest path)
      - All others are candidates for deletion, but we still
        run a byte-by-byte compare as final safety.
    """
    files_to_delete = []
    groups = 0
    duplicate_files = 0
    duplicate_bytes = 0

    for (size, _hash), paths in dup_map.items():
        if len(paths) <= 1:
            continue

        groups += 1
        # convert to strings & sort so behavior is deterministic
        paths = sorted([Path(p) for p in paths], key=lambda p: str(p))

        keeper = paths[0]  # file we keep
        for candidate in paths[1:]:
            # extra safety: verify files truly identical
            try:
                if files_are_identical(keeper, candidate):
                    files_to_delete.append(candidate)
                    duplicate_files += 1
                    duplicate_bytes += size
                else:
                    # This should basically never happen (hash + size matched),
                    # but we handle it just in case.
                    print(
                        f"WARNING: Hash match but content differs:\n"
                        f"  {keeper}\n  {candidate}"
                    )
            except (OSError, PermissionError) as e:
                print(f"Skipping comparison (error): {candidate} -> {e}")

    return files_to_delete, groups, duplicate_files, duplicate_bytes


def main():
    """
    main entry point
    """
    parser = argparse.ArgumentParser(
        description="Find and safely remove duplicate files using SHA-256 and byte-by-byte verification."
    )
    parser.add_argument("path", help="Root folder to scan")

    parser.add_argument(
        "--delete",
        action="store_true",
        help="Actually delete duplicate files (without this, it's a dry run).",
    )
    parser.add_argument(
        "--progress", action="store_true", help="Show progress while scanning."
    )
    parser.add_argument(
        "--log",
        default="deleted_duplicates.txt",
        help="Log file for deleted duplicates (default: deleted_duplicates.txt)",
    )

    args = parser.parse_args()
    root = args.path

    print(f"Scanning: {root}")
    dup_map, total_files, total_size = scan_for_duplicates(
        root, show_progress=args.progress
    )

    files_to_delete, groups, duplicate_files, duplicate_bytes = plan_deletions(dup_map)

    print("\n===== ANALYSIS =====")
    print(f"Total files scanned:       {total_files}")
    print(f"Total size scanned:        {format_size(total_size)}")
    print(f"Duplicate groups found:    {groups}")
    print(f"Duplicate files (to delete): {duplicate_files}")
    print(f"Space wasted by duplicates: {format_size(duplicate_bytes)}")
    print(f"Size if duplicates removed: {format_size(total_size - duplicate_bytes)}")

    if not files_to_delete:
        print("\nNo duplicates found. Nothing to do.")
        return

    if not args.delete:
        # Dry run
        print("\nDry run mode (no files deleted).")
        print("Example files that WOULD be deleted:")
        for p in files_to_delete[:10]:
            print(f"  {p}")
        print(
            "\nIf this looks correct, re-run with --delete to actually remove duplicates."
        )
        return

    # DELETE MODE
    print("\nDELETE MODE ENABLED. Deleting duplicates...")
    deleted = 0
    with open(args.log, "w", encoding="utf-8") as logf:
        for path in files_to_delete:
            try:
                os.remove(path)
                logf.write(str(path) + "\n")
                deleted += 1
            except OSError as e:
                print(f"Failed to delete {path}: {e}")

    print(f"\nDone. Deleted {deleted} files.")
    print(f"Deleted file list written to: {args.log}")


if __name__ == "__main__":
    main()
