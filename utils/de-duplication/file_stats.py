#!/usr/bin/env python3

"""
Scan a folder (recursively) to count files and detect duplicates via hashing.
"""

import os
import argparse
import hashlib
from collections import defaultdict
from pathlib import Path

# Define some common image and video extensions (lowercase)
IMAGE_EXTENSIONS = {
    ".jpg",
    ".jpeg",
    ".png",
    ".gif",
    ".bmp",
    ".tiff",
    ".tif",
    ".webp",
    ".heic",
    ".heif",
    ".svg",
}
VIDEO_EXTENSIONS = {
    ".mp4",
    ".mkv",
    ".avi",
    ".mov",
    ".wmv",
    ".flv",
    ".webm",
    ".mpeg",
    ".mpg",
    ".m4v",
}


def hash_file(path, chunk_size=1024 * 1024):
    """
    Compute SHA-256 hash of a file in chunks to avoid loading it all into memory.
    """
    h = hashlib.sha256()
    with open(path, "rb") as f:
        while True:
            chunk = f.read(chunk_size)
            if not chunk:
                break
            h.update(chunk)
    return h.hexdigest()


def scan_directory(root_path, show_progress=False):
    """
    scan the directory at root_path recursively.
    """
    root_path = Path(root_path)

    if not root_path.is_dir():
        raise NotADirectoryError(f"{root_path} is not a directory")

    total_files = 0
    total_size = 0  # <--- Added
    images_count = 0
    videos_count = 0
    others_count = 0

    ext_counts = defaultdict(int)
    duplicates_map = defaultdict(list)
    size_map = {}  # file path -> size

    for dirpath, dirnames, filenames in os.walk(root_path):
        for filename in filenames:
            file_path = Path(dirpath) / filename
            if not file_path.is_file():
                continue

            try:
                size = file_path.stat().st_size
            except:
                continue

            size_map[str(file_path)] = size
            total_size += size  # <--- accumulate size

            total_files += 1
            ext = file_path.suffix.lower()
            ext_counts[ext] += 1

            if ext in IMAGE_EXTENSIONS:
                images_count += 1
            elif ext in VIDEO_EXTENSIONS:
                videos_count += 1
            else:
                others_count += 1

            try:
                file_hash = hash_file(file_path)
            except:
                continue

            key = (size, file_hash)
            duplicates_map[key].append(str(file_path))

            if show_progress and total_files % 100 == 0:
                print(f"Processed {total_files} files...")

    # Duplicate statistics
    unique_files = 0
    duplicate_files = 0
    duplicate_groups = []
    duplicate_size = 0  # <--- Added
    unique_size = 0  # <--- Added

    for (size, _hash), paths in duplicates_map.items():
        if len(paths) == 1:
            unique_files += 1
            unique_size += size  # only one file
        else:
            # keep one, others are duplicates
            unique_files += 1
            unique_size += size
            duplicate_files += len(paths) - 1
            duplicate_size += size * (len(paths) - 1)
            duplicate_groups.append(paths)

    return {
        "total_files": total_files,
        "total_size": total_size,
        "images_count": images_count,
        "videos_count": videos_count,
        "others_count": others_count,
        "ext_counts": dict(ext_counts),
        "duplicate_files": duplicate_files,
        "duplicate_size": duplicate_size,
        "unique_files": unique_files,
        "unique_size": unique_size,
        "duplicate_groups": duplicate_groups,
    }


def format_size(num_bytes):
    """Convert bytes → human readable."""
    for unit in ["B", "KB", "MB", "GB", "TB"]:
        if num_bytes < 1024:
            return f"{num_bytes:.2f} {unit}"
        num_bytes /= 1024
    return f"{num_bytes:.2f} PB"


def print_summary(result, show_duplicates=False):
    """
    print a summary of the scan results.
    """

    print("\n===== FILE SUMMARY =====")
    print(f"Total files:                {result['total_files']}")
    print(f"  Images:                   {result['images_count']}")
    print(f"  Videos:                   {result['videos_count']}")
    print(f"  Other files:              {result['others_count']}\n")

    print(f"Total size before dedup:    {format_size(result['total_size'])}\n")

    print("Counts per extension:")
    for ext, count in sorted(result["ext_counts"].items()):
        label = ext if ext else "<no extension>"
        print(f"  {label:10} : {count}")

    print("\n===== DUPLICATE SUMMARY (by size + SHA-256 hash) =====")
    print(f"Total duplicate files:      {result['duplicate_files']}")
    print(f"Size wasted by duplicates:  {format_size(result['duplicate_size'])}\n")

    print(f"Unique files kept:          {result['unique_files']}")
    print(f"Total size after dedup:     {format_size(result['unique_size'])}")

    if show_duplicates and result["duplicate_groups"]:
        print("\nDuplicate groups:")
        for i, group in enumerate(result["duplicate_groups"], 1):
            print(f"\nGroup {i} ({len(group)} files):")
            for path in group:
                print(f"  {path}")


def main():
    """
    main entry point for the script.
    """
    parser = argparse.ArgumentParser(
        description="Scan a folder (recursively) to count files and detect duplicates via hashing."
    )
    parser.add_argument("path", help="Root folder to scan")
    parser.add_argument(
        "--show-duplicates", action="store_true", help="Print groups of duplicate files"
    )
    parser.add_argument(
        "--progress", action="store_true", help="Print progress every 100 files"
    )

    args = parser.parse_args()

    result = scan_directory(args.path, show_progress=args.progress)
    print_summary(result, show_duplicates=args.show_duplicates)


if __name__ == "__main__":
    main()
