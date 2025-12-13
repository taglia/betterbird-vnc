#!/bin/bash
# Wrapper script to conditionally launch BetterBird with or without --profile flag

# Debug: Log environment variables
echo "DEBUG: betterbird-wrapper.sh started" >> /tmp/betterbird-wrapper.log
echo "DEBUG: BETTERBIRD_PROFILE='$BETTERBIRD_PROFILE'" >> /tmp/betterbird-wrapper.log
echo "DEBUG: All env vars:" >> /tmp/betterbird-wrapper.log
env >> /tmp/betterbird-wrapper.log

if [ -n "$BETTERBIRD_PROFILE" ]; then
    # Use specific profile directory
    echo "DEBUG: Using custom profile: $BETTERBIRD_PROFILE" >> /tmp/betterbird-wrapper.log
    ls -la "$BETTERBIRD_PROFILE" >> /tmp/betterbird-wrapper.log 2>&1
    exec /opt/betterbird/betterbird --profile "$BETTERBIRD_PROFILE"
else
    # Let BetterBird use its default profile selection (profiles.ini)
    echo "DEBUG: Using default profile selection (profiles.ini)" >> /tmp/betterbird-wrapper.log
    exec /opt/betterbird/betterbird
fi
