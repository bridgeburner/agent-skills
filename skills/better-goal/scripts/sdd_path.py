#!/usr/bin/env python3
"""Resolve the canonical ~/.sdd tracker path for the current worktree."""

from __future__ import annotations

import argparse
import json
import os
import subprocess
import sys
from pathlib import Path


PILLAR_MARKERS = {
    "personal": ("/dev/personal/", "/src/personal/"),
    "altius": ("/dev/altius/", "/src/altius/"),
    "apex": ("/dev/apex/", "/src/apex/"),
}


def git_root(cwd: Path) -> Path:
    try:
        output = subprocess.check_output(
            ["git", "rev-parse", "--show-toplevel"],
            cwd=cwd,
            stderr=subprocess.DEVNULL,
            text=True,
        ).strip()
    except (subprocess.CalledProcessError, FileNotFoundError):
        return cwd.resolve()
    return Path(output).resolve()


def pillar_for(path: Path) -> str:
    normalized = f"{path.resolve()}/"
    for pillar, markers in PILLAR_MARKERS.items():
        if any(marker in normalized for marker in markers):
            return pillar
    raise ValueError(
        f"Could not infer project pillar for {path}. Expected path under "
        "~/dev/{personal,altius,apex}/ or ~/src/{personal,altius,apex}/."
    )


def resolve(cwd: Path) -> dict[str, str]:
    root = git_root(cwd)
    pillar = pillar_for(root)
    worktree = root.name
    sdd_root = Path.home() / ".sdd" / pillar
    tracker = sdd_root / worktree
    archive_root = sdd_root / "archive" / worktree
    return {
        "pillar": pillar,
        "worktree": worktree,
        "worktree_root": str(root),
        "tracker": str(tracker),
        "archive_root": str(archive_root),
    }


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--cwd", default=os.getcwd(), help="Directory to resolve from")
    parser.add_argument("--create", action="store_true", help="Create tracker skeleton")
    args = parser.parse_args()

    try:
        result = resolve(Path(args.cwd))
    except ValueError as exc:
        print(str(exc), file=sys.stderr)
        return 2

    if args.create:
        tracker = Path(result["tracker"])
        for name in ("designs", "evidence", "browser-evidence", "screenshots"):
            (tracker / name).mkdir(parents=True, exist_ok=True)
        Path(result["archive_root"]).mkdir(parents=True, exist_ok=True)

    print(json.dumps(result, indent=2, sort_keys=True))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
