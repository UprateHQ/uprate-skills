#!/usr/bin/env bash
set -euo pipefail

REPO_URL="https://github.com/UprateHQ/uprate-skills"
COMMANDS_DIR="$HOME/.claude/commands"
AGENTS_DIR="$HOME/.claude/agents"
TMP_DIR=$(mktemp -d)

cleanup() { rm -rf "$TMP_DIR"; }
trap cleanup EXIT

echo "Installing Uprate Skills for Claude Code..."

# Download the repo
if command -v git &>/dev/null; then
    git clone --depth 1 --quiet "$REPO_URL" "$TMP_DIR/uprate-skills"
else
    echo "Downloading..."
    curl -fsSL "$REPO_URL/archive/refs/heads/main.tar.gz" | tar -xz -C "$TMP_DIR"
    mv "$TMP_DIR"/uprate-skills-main "$TMP_DIR/uprate-skills"
fi

# Create target directories
mkdir -p "$COMMANDS_DIR/uprate"
mkdir -p "$AGENTS_DIR"

# Copy command files (slash commands)
cp -r "$TMP_DIR/uprate-skills/skills/"* "$COMMANDS_DIR/uprate/"
cp -r "$TMP_DIR/uprate-skills/agents/"* "$AGENTS_DIR/"

# Copy references
if [ -d "$TMP_DIR/uprate-skills/references" ]; then
    mkdir -p "$COMMANDS_DIR/uprate/references"
    cp -r "$TMP_DIR/uprate-skills/references/"* "$COMMANDS_DIR/uprate/references/"
fi

echo ""
echo "Uprate Skills installed successfully!"
echo ""
echo "Usage: In any project, use /uprate generate-icon"
echo ""
echo "Docs: https://github.com/UprateHQ/uprate-skills"
