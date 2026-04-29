#!/usr/bin/env python3
"""License gate — fails the build if any leaf folder under assets/ is not
attributed in LICENSES.md.

Spec §3.6 + §9.2. Idempotent. Run locally and from CI.

Exit codes:
  0  every asset leaf folder is attributed
  1  one or more asset leaf folders are missing a row
  2  LICENSES.md is malformed or missing
"""
from __future__ import annotations

import re
import sys
from pathlib import Path


REPO_ROOT = Path(__file__).resolve().parent.parent
LICENSES_MD = REPO_ROOT / "LICENSES.md"
ASSETS_DIR = REPO_ROOT / "assets"


def parse_attributed_folders(licenses_md_path: Path) -> set[str]:
    """Read LICENSES.md and return the set of folder paths mentioned in
    the `Used in` column of the asset attribution table OR in the
    `Per-folder license map` section.

    Both formats are accepted to keep the maintainer's friction low.
    """
    if not licenses_md_path.exists():
        print(f"FATAL: {licenses_md_path} is missing", file=sys.stderr)
        sys.exit(2)

    text = licenses_md_path.read_text(encoding="utf-8")
    folders: set[str] = set()

    # Match anything that looks like a path inside backticks, of the form
    # assets/<...>/  — trailing slash is optional but conventionally present.
    for m in re.finditer(r"`(assets/[^`\s]+?/?)`", text):
        path = m.group(1).rstrip("/")
        folders.add(path)

    return folders


def find_asset_leaf_folders(assets_dir: Path) -> set[str]:
    """A 'leaf folder' is a directory under assets/ that contains at least
    one file (not just other directories). We don't require attribution
    for purely organizational folders like assets/audio/.
    """
    leaves: set[str] = set()
    if not assets_dir.exists():
        return leaves

    for path in assets_dir.rglob("*"):
        if path.is_file():
            parent = path.parent
            rel = parent.relative_to(REPO_ROOT)
            leaves.add(str(rel).replace("\\", "/"))

    # Collapse to the SHALLOWEST attributed folder containing each leaf —
    # i.e. if `assets/tiles/kenney_xyz/` is attributed and a file lives at
    # `assets/tiles/kenney_xyz/Characters/Male/foo.png`, the leaf
    # `assets/tiles/kenney_xyz/Characters/Male` is covered by the
    # ancestor attribution.
    return leaves


def is_covered(leaf: str, attributed: set[str]) -> bool:
    """A leaf is covered if it equals an attributed folder OR is a
    descendant of one.
    """
    leaf_path = Path(leaf)
    for attr in attributed:
        attr_path = Path(attr)
        try:
            leaf_path.relative_to(attr_path)
            return True
        except ValueError:
            continue
    return False


def main() -> int:
    attributed = parse_attributed_folders(LICENSES_MD)
    if not attributed:
        print(
            "FATAL: LICENSES.md contains no `assets/...` paths. "
            "Add at least one row to the attribution table.",
            file=sys.stderr,
        )
        return 2

    leaves = find_asset_leaf_folders(ASSETS_DIR)

    missing = sorted(leaf for leaf in leaves if not is_covered(leaf, attributed))

    if missing:
        print("FAIL: the following asset leaf folders are not attributed:", file=sys.stderr)
        for m in missing:
            print(f"  - {m}", file=sys.stderr)
        print(
            "\nFix: add a row to LICENSES.md whose 'Used in' column "
            "contains the folder path (or an ancestor of it).",
            file=sys.stderr,
        )
        return 1

    print(f"OK: {len(leaves)} asset leaf folder(s) covered by "
          f"{len(attributed)} attribution(s).")
    return 0


if __name__ == "__main__":
    sys.exit(main())
