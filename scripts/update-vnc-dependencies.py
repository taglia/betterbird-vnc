#!/usr/bin/env python3
"""Propose newer stable noVNC/websockify releases; fail before writing on errors."""
import json
import os
from pathlib import Path
import re
import urllib.request


def main():
    path = Path("Dockerfile")
    original = path.read_text()
    updated = original
    for name, repository in (("NOVNC_VERSION", "novnc/noVNC"),
                             ("WEBSOCKIFY_VERSION", "novnc/websockify")):
        headers = {"Accept": "application/vnd.github+json"}
        if os.environ.get("GH_TOKEN"):
            headers["Authorization"] = "Bearer " + os.environ["GH_TOKEN"]
        request = urllib.request.Request(
            f"https://api.github.com/repos/{repository}/releases/latest", headers=headers)
        with urllib.request.urlopen(request, timeout=30) as response:
            release = json.load(response)
        tag = release["tag_name"]
        if release["prerelease"] or release["draft"] or not re.fullmatch(r"v\d+\.\d+\.\d+", tag):
            raise ValueError(f"Unexpected stable release for {repository}: {tag!r}")
        match = re.search(rf"^ARG {name}=(\d+\.\d+\.\d+)$", updated, re.MULTILINE)
        if not match:
            raise ValueError(f"Missing unique version declaration for {name}")
        version = tag[1:]
        if tuple(map(int, version.split('.'))) > tuple(map(int, match[1].split('.'))):
            updated = updated.replace(match[0], f"ARG {name}={version}")
            print(f"{repository}: {match[1]} -> {version}")
        else:
            print(f"{repository}: keeping {match[1]}")
    if updated != original:
        path.write_text(updated)


if __name__ == "__main__":
    main()
