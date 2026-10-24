#!/usr/bin/env python3
"""Remove obsolete tags; dry-run by default. Never delete untagged GHCR objects."""
import argparse
import base64
import json
import os
import re
import sys
import urllib.error
import urllib.parse
import urllib.request

VERSION = re.compile(r"\d+\.\d+\.\d+esr-bb\d+\Z")


def request(url, token=None, method="GET", data=None, scheme="Bearer", headers=None):
    h = dict(headers or {})
    if token:
        h["Authorization"] = f"{scheme} {token}"
    if data is not None:
        h["Content-Type"] = "application/json"
        data = json.dumps(data).encode()
    req = urllib.request.Request(url, data=data, headers=h, method=method)
    with urllib.request.urlopen(req, timeout=60) as response:
        body = response.read()
        return (json.loads(body) if body else None), response.headers


def keep_tags(tags, keep, retired):
    # Input ordered newest first; retain whole releases, not individual manifests.
    versions = list(dict.fromkeys(t for t in tags if VERSION.fullmatch(t) and t not in retired))
    return {"latest", *versions[:keep]}


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--apply", action="store_true")
    args = parser.parse_args()
    owner = os.environ["OWNER"]
    image = os.environ.get("IMAGE_NAME", "betterbird-vnc")
    user = os.environ["DOCKER_HUB_USERNAME"]
    keep = int(os.environ.get("KEEP_VERSION_TAGS", "3"))
    if keep < 1:
        raise ValueError("KEEP_VERSION_TAGS must be positive")
    retired = set(filter(None, os.environ.get("RETIRED_TAGS", "").split(',')))
    gh = os.environ["GH_TOKEN"]
    login, _ = request("https://hub.docker.com/v2/users/login/", method="POST", data={
        "username": user, "password": os.environ["DOCKER_HUB_TOKEN"]})
    hub_token = login["token"]
    hub_base = f"https://hub.docker.com/v2/repositories/{user}/{image}/tags/"
    tags = []
    url = hub_base + "?page_size=100"
    while url:
        if not url.startswith(hub_base):
            raise ValueError("Unexpected Docker Hub pagination URL")
        page, _ = request(url, hub_token, scheme="JWT")
        tags.extend(page["results"])
        url = page.get("next")
    if not any(t["name"] == "latest" for t in tags):
        raise ValueError("Refusing cleanup: Docker Hub latest is missing")
    tags.sort(key=lambda t: t["last_updated"], reverse=True)
    hub_keep = keep_tags([t["name"] for t in tags], keep, retired)

    info, _ = request(f"https://api.github.com/users/{owner}", gh)
    kind = "orgs" if info["type"] == "Organization" else "users"
    base = f"https://api.github.com/{kind}/{owner}/packages/container/{image}/versions"
    versions = []
    url = base + "?per_page=100"
    while url:
        if not url.startswith(base):
            raise ValueError("Unexpected GitHub pagination URL")
        page, headers = request(url, gh)
        versions.extend(page)
        matches = re.findall(r'<([^>]+)>; rel="next"', headers.get("Link", ""))
        url = matches[0] if matches else None
    versions.sort(key=lambda v: v["created_at"], reverse=True)
    all_tags = [t for v in versions for t in v["metadata"]["container"]["tags"]]
    if "latest" not in all_tags:
        raise ValueError("Refusing cleanup: GHCR latest is missing")
    gh_keep = keep_tags(all_tags, keep, retired)

    # Protect any child manifest referenced by retained indices, even if tagged.
    scope = urllib.parse.urlencode({"service": "ghcr.io", "scope": f"repository:{owner.lower()}/{image}:pull"})
    basic = base64.b64encode(f"{owner}:{gh}".encode()).decode()
    auth, _ = request(f"https://ghcr.io/token?{scope}", basic, scheme="Basic")
    registry_token = auth["token"]
    protected = set()

    def protect(digest):
        if digest in protected:
            return
        protected.add(digest)
        manifest, _ = request(f"https://ghcr.io/v2/{owner.lower()}/{image}/manifests/{digest}", registry_token,
                              headers={"Accept": "application/vnd.oci.image.index.v1+json, application/vnd.oci.image.manifest.v1+json, application/vnd.docker.distribution.manifest.list.v2+json, application/vnd.docker.distribution.manifest.v2+json"})
        for child in manifest.get("manifests", []):
            protect(child["digest"])

    for version in versions:
        if gh_keep.intersection(version["metadata"]["container"]["tags"]):
            protect(version["name"])

    # Build the complete plan before performing any deletion.
    deletions = []
    for tag in tags:
        name = tag["name"]
        if name in hub_keep:
            print(f"Keep Docker Hub: {name}")
        else:
            deletions.append((f"Docker Hub: {name}", hub_base + urllib.parse.quote(name, safe='') + '/', hub_token, "JWT"))
    for version in versions:
        names = version["metadata"]["container"]["tags"]
        if not names or version["name"] in protected or gh_keep.intersection(names):
            print(f"Keep GHCR {version['id']}: {','.join(names) or 'untagged (may be referenced)'}")
        else:
            deletions.append((f"GHCR {version['id']}: {','.join(names)}", f"{base}/{version['id']}", gh, "Bearer"))
    for label, url, token, scheme in deletions:
        print(f"{'Deleting' if args.apply else 'Would delete'} {label}", flush=True)
        if args.apply:
            request(url, token, method="DELETE", scheme=scheme)
    print(f"{'Deleted' if args.apply else 'Planned'} {len(deletions)} obsolete tag/version entries.")


if __name__ == "__main__":
    try:
        main()
    except urllib.error.HTTPError as error:
        # Never dump request headers or API response bodies containing credentials.
        print(f"Registry API failed: HTTP {error.code} on {error.url}", file=sys.stderr)
        sys.exit(1)
