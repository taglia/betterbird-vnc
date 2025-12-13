#!/bin/bash
# Wrapper script to conditionally launch BetterBird with or without --profile flag

if [ -n "$BETTERBIRD_PROFILE" ]; then
    # Use specific profile directory
    exec /opt/betterbird/betterbird --profile "$BETTERBIRD_PROFILE"
else
    # Let BetterBird use its default profile selection (profiles.ini)
    exec /opt/betterbird/betterbird
fi
