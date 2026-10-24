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
5. **Daily schedule** - Checks stable Betterbird/noVNC/websockify releases at 03:17 UTC
6. **Weekly schedule** - Rebuilds from fresh Debian packages Sundays at 04:41 UTC

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

- **Schedule**: Daily at 03:17 UTC (GitHub may delay scheduled runs).
- **Process**:
  1. Resolve Betterbird's stable release and official SHA-256; reject malformed metadata and downgrades.
  2. Check stable noVNC/websockify releases; Dependabot separately proposes Actions/base-image updates.
  3. Create/update a PR with pinned versions and checksum. `PAT_TOKEN` must permit creating PRs and triggering their CI.
  4. Review release notes, back up profiles before major upgrades, and merge the PR after CI passes.
  5. CI builds with `pull: true` and `no-cache: true`, checks the archive checksum and embedded application version, and scans before publication.
  6. Pull the published image and recreate your container. Existing containers are never upgraded automatically.

### Security and registry policy

Every build is fresh, including the weekly rebuild when Betterbird has not changed. The exact scanned image is pushed to both registries. Trivy blocks publication on **fixable HIGH/CRITICAL** findings; all HIGH/CRITICAL findings, including those without fixes, are retained in the `vulnerability-report` artifact. A green scan is not a guarantee that an upstream binary is vulnerability-free: monitor Betterbird/Thunderbird security advisories too.

Enable GitHub Actions failure notifications in your account notification settings and monitor failed scheduled runs/blocked update PRs. Upstream security releases may require an immediate manual dispatch rather than waiting for Sunday.

After a successful publication, cleanup preserves `latest` and three recent Betterbird release tags. Untagged GHCR objects may be OCI platform/attestation manifests, so cleanup must not indiscriminately delete them. Registry API failures fail the cleanup job rather than silently claiming success.

Local builds via `scripts/build-and-publish.sh` also pull and bypass the cache, but do not run the CI security gate; prefer CI for publication.

## Multi-Architecture Builds (Optional)

Only `linux/amd64` is currently supported. The pinned Betterbird archive is x86-64, and the scan-before-push workflow loads a single-platform image. Adding ARM64 requires an appropriate upstream binary/checksum and per-platform scanning, not just changing the platforms list.

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
