#!/usr/bin/env bash

set -euo pipefail

cd "$(dirname "$0")/.."

if rg -n "uprate-indie-push|/uprate sync|Push to Uprate|Both \(push \+ save\)|api/v1/projects|references/indie-api|pre-fill Privacy Labels" README.md skills agents references install.sh uninstall.sh; then
    echo "Found stale Indie references" >&2
    exit 1
fi

if [ -e "skills/sync.md" ] || [ -e "agents/uprate-indie-push.md" ] || [ -e "references/indie-api.md" ]; then
    echo "Found deleted Indie-only files still present" >&2
    exit 1
fi

echo "No stale Indie references found."
