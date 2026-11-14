# AGENTS.md - Guidance for AI Coding Agents

## Project Overview
Docker container packaging BetterBird email client with web-based VNC access via noVNC.

## Build Commands
```bash
docker build -t betterbird-vnc:latest .                    # Build image
docker-compose up -d                                        # Run container
scripts/build-and-publish.sh --build                        # Build via script
scripts/update-betterbird.sh                                # Check for version updates
```

## Testing
No automated tests. Manual testing: run container and access http://localhost:6080

## Code Style Guidelines
- **Shell scripts**: Use `#!/bin/bash` shebang, `set -e` for error handling
- **Variables**: Always quote (`"$VAR"`), use defaults (`${VAR:-default}`)
- **Output**: Use color constants (RED, GREEN, YELLOW, NC) for user messages
- **CLI parsing**: `while [[ $# -gt 0 ]]` with `case` statements
- **Dockerfile**: Group related commands, add comments for sections
- **Documentation**: Use fenced code blocks with language hints, tables for configs
