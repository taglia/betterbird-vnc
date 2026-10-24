#!/bin/bash
set -euo pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'
fail() { printf "${RED}%s${NC}\n" "$*" >&2; exit 1; }
CHECK=false
case "${1:-}" in
    '') ;;
    --check) CHECK=true ;;
    *) fail 'Usage: scripts/update-betterbird.sh [--check]' ;;
esac

# Resolve the official stable channel, then validate everything before modifying files.
CURL=(curl --fail --silent --show-error --location --proto '=https' --proto-redir '=https' --connect-timeout 15 --max-time 60 --retry 3)
URL=$("${CURL[@]}" 'https://www.betterbird.eu/downloads/getloc.php?os=linux&lang=en-US&version=release')
PATTERN='^https://www\.betterbird\.eu/downloads/LinuxArchive/betterbird-([0-9]+\.[0-9]+\.[0-9]+esr-bb[0-9]+)\.en-US\.linux-x86_64\.tar\.xz$'
[[ "$URL" =~ $PATTERN ]] || fail 'Unexpected upstream download URL'
LATEST_VERSION="${BASH_REMATCH[1]}"
FILENAME="${URL##*/}"
HASHES=$("${CURL[@]}" "https://www.betterbird.eu/downloads/sha256-${LATEST_VERSION%%.*}.txt")
HASH=$(printf '%s\n' "$HASHES" | awk -v file="$FILENAME" '{name=$2; sub(/^\*/, "", name); if(name==file) print $1}')
[[ "$HASH" =~ ^[a-fA-F0-9]{64}$ ]] || fail 'Missing, duplicate, or invalid upstream SHA-256'
HASH="${HASH,,}"
CURRENT_VERSION=$(<VERSION)
[[ "$CURRENT_VERSION" =~ ^[0-9]+\.[0-9]+\.[0-9]+esr-bb[0-9]+$ ]] || fail 'Invalid current VERSION'
if [[ "$CURRENT_VERSION" != "$LATEST_VERSION" ]] && [[ "$(printf '%s\n' "$CURRENT_VERSION" "$LATEST_VERSION" | sort -V | tail -1)" != "$LATEST_VERSION" ]]; then
    fail "Refusing downgrade: $CURRENT_VERSION -> $LATEST_VERSION"
fi
CURRENT_HASH=''
[[ ! -f BETTERBIRD_SHA256 ]] || CURRENT_HASH=$(<BETTERBIRD_SHA256)
# A changed hash for an already pinned release requires manual investigation.
if [[ "$CURRENT_VERSION" == "$LATEST_VERSION" && -n "$CURRENT_HASH" && "$CURRENT_HASH" != "$HASH" ]]; then
    fail 'Upstream checksum changed for the pinned version; investigate before updating'
fi
AVAILABLE=false
if [[ "$CURRENT_VERSION" != "$LATEST_VERSION" || "$CURRENT_HASH" != "$HASH" ]]; then AVAILABLE=true; fi
printf "${GREEN}Stable Betterbird: %s (current: %s)${NC}\n" "$LATEST_VERSION" "$CURRENT_VERSION"
if [[ -n "${GITHUB_OUTPUT:-}" ]]; then
    printf 'update_available=%s\nversion=%s\n' "$AVAILABLE" "$LATEST_VERSION" >> "$GITHUB_OUTPUT"
fi
if [[ "$CHECK" == true || "$AVAILABLE" == false ]]; then
    printf '%bNo files changed.%b\n' "$YELLOW" "$NC"
    exit 0
fi
# Require the expected declarations so an upstream/source layout change fails loudly.
[[ $(grep -c '^ARG BETTERBIRD_VERSION=' Dockerfile) == 1 ]] || fail 'Missing/duplicate Dockerfile version'
[[ $(grep -c '^ARG BETTERBIRD_SHA256=' Dockerfile) == 1 ]] || fail 'Missing/duplicate Dockerfile checksum'
[[ $(grep -c '^[[:space:]]*BETTERBIRD_VERSION:' docker-compose.yml) == 1 ]] || fail 'Missing/duplicate compose version'
[[ $(grep -c '^[[:space:]]*BETTERBIRD_SHA256:' docker-compose.yml) == 1 ]] || fail 'Missing/duplicate compose checksum'
printf '%s\n' "$LATEST_VERSION" > VERSION
printf '%s\n' "$HASH" > BETTERBIRD_SHA256
sed -i "s/^ARG BETTERBIRD_VERSION=.*/ARG BETTERBIRD_VERSION=$LATEST_VERSION/; s/^ARG BETTERBIRD_SHA256=.*/ARG BETTERBIRD_SHA256=$HASH/" Dockerfile
sed -i "s/^\([[:space:]]*BETTERBIRD_VERSION:\).*/\1 $LATEST_VERSION/; s/^\([[:space:]]*BETTERBIRD_SHA256:\).*/\1 $HASH/" docker-compose.yml
printf '%bUpdated version and checksum. Review, build, and test before publishing.%b\n' "$GREEN" "$NC"
