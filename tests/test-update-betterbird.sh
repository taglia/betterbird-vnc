#!/bin/bash
set -euo pipefail
ROOT=$(cd "$(dirname "$0")/.." && pwd)
TMP=$(mktemp -d)
trap 'rm -rf "$TMP"' EXIT
mkdir -p "$TMP/bin"
cat > "$TMP/bin/curl" <<'MOCK'
#!/bin/bash
set -e
[[ "${MOCK_FAIL:-false}" != true ]] || exit 22
case "${*: -1}" in
    *getloc.php*) printf '%s\n' "${MOCK_URL:-https://www.betterbird.eu/downloads/LinuxArchive/betterbird-${MOCK_VERSION}.en-US.linux-x86_64.tar.xz}" ;;
    *sha256-*)
        printf '%s\n' "${MOCK_HASH} *betterbird-${MOCK_VERSION}.en-US.linux-x86_64.tar.xz"
        if [[ "${MOCK_DUPLICATE:-false}" == true ]]; then
            printf '%s\n' "${MOCK_HASH} *betterbird-${MOCK_VERSION}.en-US.linux-x86_64.tar.xz"
        fi
        ;;
    *) exit 2 ;;
esac
MOCK
chmod +x "$TMP/bin/curl"
export PATH="$TMP/bin:$PATH"
export MOCK_VERSION=153.5.0esr-bb11
export MOCK_HASH=253b1760c9b7a5502a210c90d530f87eebdcae87b7af13af213d50ffb255dc11
cd "$TMP"
fixture() {
    unset MOCK_FAIL MOCK_URL
    printf '%s\n' 153.4.0esr-bb10 > VERSION
    printf '%064d\n' 0 > BETTERBIRD_SHA256
    printf 'ARG BETTERBIRD_VERSION=153.4.0esr-bb10\nARG BETTERBIRD_SHA256=%064d\n' 0 > Dockerfile
    printf '        BETTERBIRD_VERSION: 153.4.0esr-bb10\n        BETTERBIRD_SHA256: %064d\n' 0 > docker-compose.yml
}
snapshot() { sha256sum VERSION BETTERBIRD_SHA256 Dockerfile docker-compose.yml; }
reject() {
    local before
    before=$(snapshot)
    if bash "$ROOT/scripts/update-betterbird.sh"; then echo 'Expected failure' >&2; exit 1; fi
    [[ "$(snapshot)" == "$before" ]]
}
fixture
before=$(snapshot)
bash "$ROOT/scripts/update-betterbird.sh" --check
[[ "$(snapshot)" == "$before" ]]
bash "$ROOT/scripts/update-betterbird.sh"
[[ "$(<VERSION)" == "$MOCK_VERSION" && "$(<BETTERBIRD_SHA256)" == "$MOCK_HASH" ]]
grep -q "^ARG BETTERBIRD_VERSION=$MOCK_VERSION$" Dockerfile
grep -q "BETTERBIRD_SHA256: $MOCK_HASH$" docker-compose.yml
before=$(snapshot)
bash "$ROOT/scripts/update-betterbird.sh"
[[ "$(snapshot)" == "$before" ]]
fixture; export MOCK_FAIL=true; reject
fixture; export MOCK_URL=https://evil.example/betterbird-153.5.0esr-bb11.en-US.linux-x86_64.tar.xz; reject
fixture; export MOCK_HASH=invalid; reject
export MOCK_HASH=253b1760c9b7a5502a210c90d530f87eebdcae87b7af13af213d50ffb255dc11
fixture; printf '%s\n' 153.6.0esr-bb12 > VERSION; reject
fixture; printf '%s\n' "$MOCK_VERSION" > VERSION; reject
fixture; export MOCK_DUPLICATE=true; reject
printf 'All updater tests passed.\n'
