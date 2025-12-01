#!/bin/bash
set -e

echo "BetterBird Version Update Script"
echo "=================================="

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Configuration
BETTERBIRD_DOWNLOAD_URL="https://www.betterbird.eu/downloads/get.php?os=linux&lang=en-US&version=release"
VERSION_FILE="VERSION"

echo "Checking for latest BetterBird version..."

# Follow the redirect to get the actual filename which contains the version
LATEST_VERSION=$(curl -sI "$BETTERBIRD_DOWNLOAD_URL" | \
    grep -i "^location:" | \
    grep -oP 'betterbird-\K[0-9]+\.[0-9]+\.[0-9]+esr-bb[0-9]+' | \
    head -1)

if [ -z "$LATEST_VERSION" ]; then
    echo -e "${RED}Error: Could not fetch latest version${NC}"
    exit 1
fi

echo -e "${GREEN}Latest BetterBird version: $LATEST_VERSION${NC}"

# Read current version if exists
CURRENT_VERSION=""
if [ -f "$VERSION_FILE" ]; then
    CURRENT_VERSION=$(cat "$VERSION_FILE")
    echo -e "Current version in VERSION file: $CURRENT_VERSION"
fi

# Check if we need to update
if [ "$CURRENT_VERSION" = "$LATEST_VERSION" ]; then
    echo -e "${YELLOW}Already using the latest version!${NC}"
    echo "No update needed."
    exit 0
fi

echo ""
echo -e "${YELLOW}Update available!${NC}"
echo "  Current: $CURRENT_VERSION"
echo "  Latest:  $LATEST_VERSION"
echo ""

# Update VERSION file
echo "$LATEST_VERSION" > "$VERSION_FILE"
echo -e "${GREEN}Updated VERSION file to $LATEST_VERSION${NC}"

# Update Dockerfile
if [ -f "Dockerfile" ]; then
    echo "Updating Dockerfile..."
    sed -i "s/ARG BETTERBIRD_VERSION=.*/ARG BETTERBIRD_VERSION=$LATEST_VERSION/" Dockerfile
    echo -e "${GREEN}Updated Dockerfile${NC}"
fi

# Update docker-compose.yml
if [ -f "docker-compose.yml" ]; then
    echo "Updating docker-compose.yml..."
    sed -i "s/BETTERBIRD_VERSION: .*/BETTERBIRD_VERSION: $LATEST_VERSION/" docker-compose.yml
    echo -e "${GREEN}Updated docker-compose.yml${NC}"
fi

echo ""
echo -e "${GREEN}Update complete!${NC}"
echo ""
echo "Next steps:"
echo "  1. Review the changes with: git diff"
echo "  2. Build the new image with: scripts/build-and-publish.sh --build"
echo "  3. Test the new image locally"
echo "  4. Publish with: scripts/build-and-publish.sh --publish"
echo ""
