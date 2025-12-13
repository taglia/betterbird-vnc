#!/bin/bash
# Wrapper script to conditionally launch BetterBird with or without --profile flag

# Export all current environment variables to ensure they're passed to Betterbird
# This allows users to set any custom environment variables in docker-compose.yml
export $(env | cut -d= -f1)

if [ -n "$BETTERBIRD_PROFILE" ]; then
    # Use specific profile directory
    exec /opt/betterbird/betterbird --profile "$BETTERBIRD_PROFILE"
else
    # Let BetterBird use its default profile selection (profiles.ini)
    exec /opt/betterbird/betterbird
fi
