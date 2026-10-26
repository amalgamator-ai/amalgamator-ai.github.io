#!/usr/bin/env python3
"""Copy amalgamator community policy markdown into .cache/community with Hugo front matter."""

from __future__ import annotations

import argparse
import re
import shutil
from pathlib import Path

# dest stem → (source filename, title, weight, lede)
PAGES: dict[str, tuple[str, str, int, str]] = {
    "contributing": (
        "CONTRIBUTING.md",
        "Contributing",
        10,
        "How to set up a development environment and get a change merged.",
    ),
    "code-of-conduct": (
        "CODE_OF_CONDUCT.md",
        "Code of conduct",
        20,
        "Expected standards for participating in the Amalgamator community.",
    ),
    "security": (
        "SECURITY.md",
        "Security policy",
        30,
        "How to report vulnerabilities responsibly.",
    ),
}


def strip_existing_front_matter(body: str) -> str:
    if body.startswith("---"):
        match = re.match(r"^---\n.*?\n---\n?", body, flags=re.DOTALL)
        if match:
            return body[match.end() :]
    return body


def strip_leading_h1(body: str) -> str:
    return re.sub(r"(?m)^\s*#\s+[^\n]+\n+", "", body, count=1)


def front_matter(title: str, weight: int, lede: str) -> str:
    return "\n".join(
        [
            "---",
            f'title: "{title}"',
            f"weight: {weight}",
            f'lede: "{lede}"',
            "type: community",
            "---",
            "",
        ]
    )


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        "--source",
        type=Path,
        required=True,
        help="Amalgamator repository root (contains CONTRIBUTING.md, etc.)",
    )
    parser.add_argument("--dest", type=Path, required=True)
    args = parser.parse_args()

    source: Path = args.source
    dest: Path = args.dest

    if dest.exists():
        shutil.rmtree(dest)
    dest.mkdir(parents=True)

    missing: list[str] = []
    for stem, (filename, title, weight, lede) in PAGES.items():
        src = source / filename
        if not src.is_file():
            missing.append(filename)
            continue
        body = strip_leading_h1(strip_existing_front_matter(src.read_text(encoding="utf-8")))
        (dest / f"{stem}.md").write_text(
            front_matter(title, weight, lede) + body.lstrip("\n"),
            encoding="utf-8",
        )

    if missing:
        raise SystemExit(
            f"Missing community files in {source}: {', '.join(missing)}"
        )

    print(f"Prepared community pages → {dest}")


if __name__ == "__main__":
    main()
