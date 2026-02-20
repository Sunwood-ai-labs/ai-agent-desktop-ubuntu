#!/usr/bin/with-contenv bash

# This script ensures that desktop shortcuts for Antigravity and Google Search
# are present in the user's Desktop folder.

DESKTOP_DIR="/config/Desktop"

echo "Ensuring desktop shortcuts are present in $DESKTOP_DIR..."

mkdir -p "$DESKTOP_DIR"

if [ ! -f "$DESKTOP_DIR/antigravity.desktop" ]; then
    cp /defaults/Desktop/antigravity.desktop "$DESKTOP_DIR/"
    chown abc:abc "$DESKTOP_DIR/antigravity.desktop"
fi

if [ ! -f "$DESKTOP_DIR/search.desktop" ]; then
    cp /defaults/Desktop/search.desktop "$DESKTOP_DIR/"
    chown abc:abc "$DESKTOP_DIR/search.desktop"
fi
