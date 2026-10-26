"""Minimal .env loader (no third-party deps). Does not override existing env."""
from __future__ import annotations

import os
from pathlib import Path


def load_dotenv(path: str | Path | None = None) -> Path | None:
    if path is None:
        path = Path(__file__).resolve().parents[2] / ".env"
    else:
        path = Path(path)
    if not path.is_file():
        return None
    for line in path.read_text(encoding="utf-8").splitlines():
        line = line.strip()
        if not line or line.startswith("#") or "=" not in line:
            continue
        key, _, val = line.partition("=")
        key = key.strip()
        val = val.strip().strip("'").strip('"')
        if key and key not in os.environ:
            os.environ[key] = val
    return path


if __name__ == "__main__":
    print("loaded", load_dotenv())
