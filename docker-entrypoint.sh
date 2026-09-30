#!/bin/bash
# ==============================================================================
# @file       docker-entrypoint.sh
# @brief      Runtime access control entrypoint for Gestell Mini-ECU container
# @company    Gestell Company
# ==============================================================================

# If running in CI (GitHub Actions) with GESTELL_CI=true, skip the token check
if [ "$GESTELL_CI" = "true" ]; then
    exec "$@"
    exit 0
fi

# Require GESTELL_TOKEN at runtime
if [ -z "$GESTELL_TOKEN" ]; then
    echo ""
    echo "============================================================"
    echo "  ACCESS DENIED — Gestell Automotive Mini-ECU Container"
    echo "============================================================"
    echo "  GESTELL_TOKEN environment variable is required."
    echo "  Usage:"
    echo "    docker run -e GESTELL_TOKEN=<secret> gestell-ecu <cmd>"
    echo "    docker compose run -e GESTELL_TOKEN=<secret> dev"
    echo "============================================================"
    echo ""
    exit 1
fi

# Verify token hash
PROVIDED_HASH=$(echo -n "$GESTELL_TOKEN" | sha256sum | awk '{print $1}')
if [ "$PROVIDED_HASH" != "$GESTELL_TOKEN_HASH" ]; then
    echo ""
    echo "============================================================"
    echo "  ACCESS DENIED — Invalid Token"
    echo "  Contact your team lead for the correct access token."
    echo "============================================================"
    echo ""
    exit 1
fi

echo ""
echo "  Gestell Automotive Mini-ECU — Development Environment"
echo "  Access granted. Welcome, team member!"
echo ""
exec "$@"
