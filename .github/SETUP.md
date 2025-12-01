# GitHub Actions Setup Guide

This guide explains how to configure GitHub Actions for automated Docker image builds and publishing.

## Required Secrets

You need to configure the following secrets in your GitHub repository:

### 1. Docker Hub Credentials

Go to: **Repository Settings → Secrets and variables → Actions → New repository secret**

#### `DOCKER_HUB_USERNAME`
- Your Docker Hub username
- Example: `johndoe`

#### `DOCKER_HUB_TOKEN`
- Docker Hub Access Token (NOT your password)
- **How to create:**
  1. Go to https://hub.docker.com/settings/security
  2. Click "New Access Token"
  3. Give it a name (e.g., "GitHub Actions")
  4. Set permissions to "Read, Write, Delete"
  5. Copy the token (you won't see it again!)

### 2. GitHub Token (GITHUB_TOKEN)

✅ **No setup needed!** This is automatically provided by GitHub Actions.

## Permissions

Ensure your repository has the correct permissions:

1. Go to **Repository Settings → Actions → General**
2. Under "Workflow permissions":
   - Select "Read and write permissions"
   - Check "Allow GitHub Actions to create and approve pull requests"

## Registries

The workflow publishes to both:
- **Docker Hub**: `docker.io/tagliasteel/betterbird-vnc`
- **GitHub Container Registry**: `ghcr.io/taglia/betterbird-vnc`

## Workflow Triggers

The GitHub Action runs on:

1. **Push to main branch** - Builds and publishes `latest` tag
2. **Git tags** - Builds and publishes versioned tags (e.g., `v1.0.0`)
3. **Pull requests** - Builds only (no publishing)
4. **Manual dispatch** - Run manually from Actions tab
5. **Weekly schedule** - Checks for BetterBird updates every Sunday at 2 AM UTC

## Manual Workflow Dispatch

You can manually trigger a build:

1. Go to **Actions** tab in your repository
2. Click "Build and Publish Docker Images"
3. Click "Run workflow"
4. Select branch and click "Run workflow"

## Testing the Setup

### Option 1: Push to main branch
```bash
git add .
git commit -m "Test GitHub Actions"
git push origin main
```

### Option 2: Create a git tag
```bash
git tag v1.0.0
git push origin v1.0.0
```

### Option 3: Manual dispatch
Use the GitHub web interface as described above.

## Viewing Build Logs

1. Go to **Actions** tab
2. Click on the latest workflow run
3. Click on the "build-and-push" job to see logs

## Automatic Version Updates

The workflow includes automatic version checking:

- **Schedule**: Runs every Sunday at 2 AM UTC
- **Process**:
  1. Runs `scripts/update-betterbird.sh`
  2. If a new BetterBird version is found
  3. Creates a Pull Request with the updated version
  4. You review and merge the PR
  5. Merging triggers a new build automatically

## Multi-Architecture Builds (Optional)

To build for multiple architectures (e.g., ARM64):

Edit `.github/workflows/build-and-publish.yml`:

```yaml
platforms: linux/amd64,linux/arm64
```

Note: ARM64 builds take significantly longer (~30-60 minutes).

## Troubleshooting

### Error: "username and password required"
- Check that `DOCKER_HUB_USERNAME` and `DOCKER_HUB_TOKEN` secrets are set correctly
- Verify the token has "Read, Write, Delete" permissions

### Error: "denied: permission_denied"
- For GHCR: Check repository permissions allow packages write
- Go to **Settings → Actions → General → Workflow permissions**

### Error: "image not found" when pulling
- Ensure the build completed successfully
- Check the package visibility (public vs private)
- For GHCR: Make package public in **Packages** tab

### Docker Hub README not updating
- Verify `DOCKER_HUB_README.md` exists in repository root
- Check the `DOCKER_HUB_TOKEN` has write permissions
- Review the "Update Docker Hub description" step logs

## Package Visibility

### GitHub Container Registry
After first push, make the package public:

1. Go to your profile → **Packages**
2. Click on `betterbird-vnc`
3. Click **Package settings**
4. Scroll to "Danger Zone"
5. Click "Change visibility" → "Public"

### Docker Hub
Repositories are public by default for free accounts.

## Cleanup

To disable the workflow:
1. Go to **.github/workflows/build-and-publish.yml**
2. Add at the top:
```yaml
on: []  # Disables all triggers
```

Or delete the file entirely.
