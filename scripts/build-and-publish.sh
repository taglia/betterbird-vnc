#!/bin/bash
set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
DOCKER_USERNAME="${DOCKER_USERNAME:-}"
GITHUB_USERNAME="${GITHUB_USERNAME:-}"
IMAGE_NAME="${IMAGE_NAME:-betterbird-vnc}"
VERSION_FILE="VERSION"
PLATFORMS="linux/amd64"  # Add "linux/arm64" if you want multi-arch
REGISTRIES="${REGISTRIES:-dockerhub,ghcr}"  # Comma-separated list

# Function to display usage
usage() {
    echo "Usage: $0 [OPTIONS]"
    echo ""
    echo "Build and publish BetterBird Docker image to multiple registries"
    echo ""
    echo "Options:"
    echo "  --build              Build the Docker image only"
    echo "  --publish            Publish to registries (requires login)"
    echo "  --build-and-publish  Build and publish in one step"
    echo "  --docker-username USERNAME  Docker Hub username (or set DOCKER_USERNAME env var)"
    echo "  --github-username USERNAME  GitHub username (or set GITHUB_USERNAME env var)"
    echo "  --image-name NAME    Image name (default: betterbird-vnc)"
    echo "  --registries LIST    Comma-separated registries: dockerhub,ghcr (default: both)"
    echo "  --platforms PLATFORMS Platforms to build for (default: linux/amd64)"
    echo "  --help               Show this help message"
    echo ""
    echo "Examples:"
    echo "  $0 --build --docker-username myuser --github-username myuser"
    echo "  $0 --publish --docker-username myuser --github-username myuser"
    echo "  $0 --build-and-publish --docker-username myuser --github-username myuser"
    echo "  $0 --registries ghcr --github-username myuser --build-and-publish"
    echo ""
    echo "Environment Variables:"
    echo "  DOCKER_USERNAME=myuser GITHUB_USERNAME=myuser $0 --build-and-publish"
    echo ""
    exit 1
}

# Function to get version
get_version() {
    if [ ! -f "$VERSION_FILE" ]; then
        echo -e "${RED}Error: VERSION file not found${NC}"
        echo "Run scripts/update-betterbird.sh first to create it"
        exit 1
    fi
    cat "$VERSION_FILE"
}

# Function to check if registry is enabled
is_registry_enabled() {
    local registry=$1
    [[ ",$REGISTRIES," == *",$registry,"* ]]
}

# Function to build image
build_image() {
    local version=$1
    
    echo -e "${BLUE}Building Docker image...${NC}"
    echo "  Version: $version"
    echo "  Image Name: $IMAGE_NAME"
    echo "  Platforms: $PLATFORMS"
    echo "  Enabled Registries: $REGISTRIES"
    echo ""
    
    # Build the base image
    docker build \
        --build-arg BETTERBIRD_VERSION="$version" \
        -t "$IMAGE_NAME:$version" \
        -t "$IMAGE_NAME:latest" \
        .
    
    echo -e "${GREEN}Build completed successfully!${NC}"
    echo ""
    
    # Tag for Docker Hub
    if is_registry_enabled "dockerhub"; then
        if [ -z "$DOCKER_USERNAME" ]; then
            echo -e "${YELLOW}Warning: Docker Hub enabled but DOCKER_USERNAME not set${NC}"
            echo "Skipping Docker Hub tags..."
        else
            echo "Tagging for Docker Hub..."
            docker tag "$IMAGE_NAME:$version" "$DOCKER_USERNAME/$IMAGE_NAME:$version"
            docker tag "$IMAGE_NAME:latest" "$DOCKER_USERNAME/$IMAGE_NAME:latest"
            echo "  $DOCKER_USERNAME/$IMAGE_NAME:$version"
            echo "  $DOCKER_USERNAME/$IMAGE_NAME:latest"
        fi
    fi
    
    # Tag for GitHub Container Registry
    if is_registry_enabled "ghcr"; then
        if [ -z "$GITHUB_USERNAME" ]; then
            echo -e "${YELLOW}Warning: GHCR enabled but GITHUB_USERNAME not set${NC}"
            echo "Skipping GHCR tags..."
        else
            echo "Tagging for GitHub Container Registry..."
            docker tag "$IMAGE_NAME:$version" "ghcr.io/$GITHUB_USERNAME/$IMAGE_NAME:$version"
            docker tag "$IMAGE_NAME:latest" "ghcr.io/$GITHUB_USERNAME/$IMAGE_NAME:latest"
            echo "  ghcr.io/$GITHUB_USERNAME/$IMAGE_NAME:$version"
            echo "  ghcr.io/$GITHUB_USERNAME/$IMAGE_NAME:latest"
        fi
    fi
    
    echo ""
}

# Function to publish to Docker Hub
publish_dockerhub() {
    local version=$1
    
    if [ -z "$DOCKER_USERNAME" ]; then
        echo -e "${YELLOW}Skipping Docker Hub (DOCKER_USERNAME not set)${NC}"
        return
    fi
    
    echo -e "${BLUE}Publishing to Docker Hub...${NC}"
    
    # Check if user is logged in
    if ! docker info 2>/dev/null | grep -q "Username:"; then
        echo -e "${YELLOW}Warning: You may not be logged in to Docker Hub${NC}"
        echo "Please run: docker login"
        read -p "Continue anyway? (y/N) " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            return
        fi
    fi
    
    # Push version tag
    echo "Pushing $DOCKER_USERNAME/$IMAGE_NAME:$version..."
    docker push "$DOCKER_USERNAME/$IMAGE_NAME:$version"
    
    # Push latest tag
    echo "Pushing $DOCKER_USERNAME/$IMAGE_NAME:latest..."
    docker push "$DOCKER_USERNAME/$IMAGE_NAME:latest"
    
    echo -e "${GREEN}Published to Docker Hub successfully!${NC}"
    echo "  docker pull $DOCKER_USERNAME/$IMAGE_NAME:$version"
    echo "  docker pull $DOCKER_USERNAME/$IMAGE_NAME:latest"
    echo ""
}

# Function to publish to GitHub Container Registry
publish_ghcr() {
    local version=$1
    
    if [ -z "$GITHUB_USERNAME" ]; then
        echo -e "${YELLOW}Skipping GHCR (GITHUB_USERNAME not set)${NC}"
        return
    fi
    
    echo -e "${BLUE}Publishing to GitHub Container Registry...${NC}"
    
    # Check if user is logged in to ghcr.io
    if ! docker info 2>/dev/null | grep -q "ghcr.io"; then
        echo -e "${YELLOW}Tip: Login to GHCR with:${NC}"
        echo "  echo \$GITHUB_TOKEN | docker login ghcr.io -u $GITHUB_USERNAME --password-stdin"
        echo ""
    fi
    
    # Push version tag
    echo "Pushing ghcr.io/$GITHUB_USERNAME/$IMAGE_NAME:$version..."
    docker push "ghcr.io/$GITHUB_USERNAME/$IMAGE_NAME:$version"
    
    # Push latest tag
    echo "Pushing ghcr.io/$GITHUB_USERNAME/$IMAGE_NAME:latest..."
    docker push "ghcr.io/$GITHUB_USERNAME/$IMAGE_NAME:latest"
    
    echo -e "${GREEN}Published to GHCR successfully!${NC}"
    echo "  docker pull ghcr.io/$GITHUB_USERNAME/$IMAGE_NAME:$version"
    echo "  docker pull ghcr.io/$GITHUB_USERNAME/$IMAGE_NAME:latest"
    echo ""
}

# Function to publish to all enabled registries
publish_all() {
    local version=$1
    
    if is_registry_enabled "dockerhub"; then
        publish_dockerhub "$version"
    fi
    
    if is_registry_enabled "ghcr"; then
        publish_ghcr "$version"
    fi
    
    echo -e "${GREEN}All enabled registries published!${NC}"
}

# Parse arguments
ACTION=""
while [[ $# -gt 0 ]]; do
    case $1 in
        --build)
            ACTION="build"
            shift
            ;;
        --publish)
            ACTION="publish"
            shift
            ;;
        --build-and-publish)
            ACTION="both"
            shift
            ;;
        --docker-username)
            DOCKER_USERNAME="$2"
            shift 2
            ;;
        --github-username)
            GITHUB_USERNAME="$2"
            shift 2
            ;;
        --username)
            # Backward compatibility: set both usernames
            DOCKER_USERNAME="$2"
            GITHUB_USERNAME="$2"
            shift 2
            ;;
        --image-name)
            IMAGE_NAME="$2"
            shift 2
            ;;
        --registries)
            REGISTRIES="$2"
            shift 2
            ;;
        --platforms)
            PLATFORMS="$2"
            shift 2
            ;;
        --help)
            usage
            ;;
        *)
            echo -e "${RED}Error: Unknown option $1${NC}"
            usage
            ;;
    esac
done

# Validate inputs
if [ -z "$ACTION" ]; then
    echo -e "${RED}Error: No action specified${NC}"
    usage
fi

# Check if at least one username is provided for enabled registries
if is_registry_enabled "dockerhub" && [ -z "$DOCKER_USERNAME" ]; then
    echo -e "${YELLOW}Warning: Docker Hub enabled but DOCKER_USERNAME not set${NC}"
fi

if is_registry_enabled "ghcr" && [ -z "$GITHUB_USERNAME" ]; then
    echo -e "${YELLOW}Warning: GHCR enabled but GITHUB_USERNAME not set${NC}"
fi

if [ -z "$DOCKER_USERNAME" ] && [ -z "$GITHUB_USERNAME" ]; then
    echo -e "${RED}Error: At least one username must be specified${NC}"
    echo "Use --docker-username, --github-username, or --username for both"
    exit 1
fi

# Get version
VERSION=$(get_version)

echo "===================================="
echo "BetterBird Docker Build & Publish"
echo "===================================="
echo "  Version: $VERSION"
echo "  Docker Hub: ${DOCKER_USERNAME:-not set}"
echo "  GitHub: ${GITHUB_USERNAME:-not set}"
echo "  Image: $IMAGE_NAME"
echo "  Registries: $REGISTRIES"
echo "  Action: $ACTION"
echo "===================================="
echo ""

# Execute action
case $ACTION in
    build)
        build_image "$VERSION"
        echo -e "${YELLOW}Next steps:${NC}"
        echo "  1. Test the image: docker run -p 6080:6080 $IMAGE_NAME:$VERSION"
        echo "  2. Publish with: $0 --publish"
        ;;
    publish)
        # Check if base image exists locally
        if ! docker image inspect "$IMAGE_NAME:$VERSION" &>/dev/null; then
            echo -e "${RED}Error: Image $IMAGE_NAME:$VERSION not found locally${NC}"
            echo "Build it first with: $0 --build"
            exit 1
        fi
        publish_all "$VERSION"
        ;;
    both)
        build_image "$VERSION"
        echo ""
        read -p "Build successful. Proceed with publish? (y/N) " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            publish_all "$VERSION"
        else
            echo "Publish cancelled."
            echo "You can publish later with: $0 --publish"
        fi
        ;;
esac

echo -e "${GREEN}Done!${NC}"
