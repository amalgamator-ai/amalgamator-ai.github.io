#!/usr/bin/env python3
"""Copy amalgamator docs into .cache/docs and inject Hugo front matter."""

from __future__ import annotations

import argparse
import re
import shutil
from pathlib import Path

try:
    import yaml
except ImportError:
    yaml = None  # type: ignore


def load_nav(path: Path) -> dict[str, dict]:
    text = path.read_text(encoding="utf-8")
    if yaml is not None:
        data = yaml.safe_load(text)
    else:
        data = _parse_nav_fallback(text)
    pages = data.get("pages") or []
    return {p["path"]: p for p in pages}


def _parse_nav_fallback(text: str) -> dict:
    """Minimal YAML subset parser when PyYAML is unavailable."""
    pages: list[dict] = []
    current: dict | None = None
    for raw in text.splitlines():
        line = raw.split("#", 1)[0].rstrip()
        if not line.strip():
            continue
        if line.strip().startswith("- path:"):
            if current:
                pages.append(current)
            current = {"path": line.split(":", 1)[1].strip()}
        elif current is None:
            continue
        elif "title:" in line:
            current["title"] = line.split(":", 1)[1].strip()
        elif "weight:" in line:
            current["weight"] = int(line.split(":", 1)[1].strip())
        elif "section:" in line:
            current["section"] = line.split(":", 1)[1].strip().lower() in (
                "true",
                "yes",
                "1",
            )
    if current:
        pages.append(current)
    return {"pages": pages}


def strip_existing_front_matter(body: str) -> str:
    if body.startswith("---"):
        match = re.match(r"^---\n.*?\n---\n?", body, flags=re.DOTALL)
        if match:
            return body[match.end() :]
    return body


def strip_leading_h1(body: str) -> str:
    """Remove the first ATX H1 so the layout title is the only page header."""
    return re.sub(r"(?m)^\s*#\s+[^\n]+\n+", "", body, count=1)


def front_matter(meta: dict, *, kind: str = "page") -> str:
    lines = [
        "---",
        f'title: "{meta["title"]}"',
        f"weight: {meta.get('weight', 100)}",
        "type: docs",
    ]
    lines.append("---")
    lines.append("")
    return "\n".join(lines)


def resolve_source_file(source_root: Path, rel_path: str, is_section: bool) -> Path | None:
    if is_section:
        for name in ("_index.md", "README.md", "overview.md"):
            candidate = source_root / rel_path / name
            if candidate.is_file():
                return candidate
        # Section with only children: synthesize empty index later
        if (source_root / rel_path).is_dir():
            return None
        return None
    md = source_root / f"{rel_path}.md"
    if md.is_file():
        return md
    return None


def write_page(dest: Path, meta: dict, body: str, *, kind: str = "page") -> None:
    dest.parent.mkdir(parents=True, exist_ok=True)
    cleaned = strip_leading_h1(strip_existing_front_matter(body))
    dest.write_text(front_matter(meta, kind=kind) + cleaned, encoding="utf-8")


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--source", type=Path, required=True)
    parser.add_argument("--dest", type=Path, required=True)
    parser.add_argument("--nav", type=Path, required=True)
    args = parser.parse_args()

    source: Path = args.source
    dest: Path = args.dest
    nav = load_nav(args.nav)

    if dest.exists():
        shutil.rmtree(dest)
    dest.mkdir(parents=True)

    # Copy tree first so unlisted files still appear if needed.
    for path in source.rglob("*"):
        if not path.is_file():
            continue
        if path.suffix.lower() not in {".md", ".png", ".jpg", ".jpeg", ".gif", ".svg", ".webp"}:
            continue
        rel = path.relative_to(source)
        if rel.name.lower() == "readme.md" and rel.parent == Path("."):
            continue  # product docs README is not the Hugo docs landing
        target = dest / rel
        target.parent.mkdir(parents=True, exist_ok=True)
        shutil.copy2(path, target)

    # Rewrite known pages with front matter and Hugo-friendly names.
    for rel_path, meta in nav.items():
        is_section = bool(meta.get("section"))
        src = resolve_source_file(source, rel_path, is_section)

        if is_section:
            out = dest / rel_path / "_index.md"
            # Remove overview.md if we promote it to _index
            overview = dest / rel_path / "overview.md"
            if src and src.name == "overview.md" and overview.exists():
                overview.unlink()
            readme = dest / rel_path / "README.md"
            if readme.exists():
                readme.unlink()
            body = src.read_text(encoding="utf-8") if src else f"# {meta['title']}\n"
            write_page(out, meta, body, kind="section")
            continue

        out = dest / f"{rel_path}.md"
        if src is None:
            continue
        # Drop raw copy if path differed (e.g. we only rewrite in place)
        body = src.read_text(encoding="utf-8")
        write_page(out, meta, body)

    # Inject front matter into any remaining .md without ---
    for path in dest.rglob("*.md"):
        text = path.read_text(encoding="utf-8")
        if text.startswith("---"):
            continue
        title = path.stem.replace("-", " ").replace("_", " ").title()
        if path.name == "_index.md":
            title = path.parent.name.replace("-", " ").title() or title
        write_page(path, {"title": title, "weight": 100}, text)

    print(f"Prepared docs → {dest}")


if __name__ == "__main__":
    main()
