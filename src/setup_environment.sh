#!/bin/bash

GODOT_SQL_TAG="v4.8"
GODOT_SQL_URL="https://github.com/2shady4u/godot-sqlite/releases/download/${GODOT_SQL_TAG}/addons.zip"
GODOT_SQL_HASH="f81531b5b9f1d4f422e9f882c409701adf197a17f894ca65ee2fa25759c25270"

echo ""
echo "This script will download all of the required addons that are not currently present in the repository."
echo ""
sleep 3s

mkdir -p "setup_downloads"

echo "Downloading 'godot-sqlite' tagged '${GODOT_SQL_TAG}'"

# Download Godot-SQLite
if [ ! -f "setup_downloads/godot-sqlite.zip" ]; then
	curl -sSL -H "Accept: application/octet-stream" -o "setup_downloads/godot-sqlite.zip" "${GODOT_SQL_URL}" 
fi

# Validate SHA256
downloaded_godot_sql_hash=$(sha256sum "setup_downloads/godot-sqlite.zip" | awk '{print $1}' )
if [ $downloaded_godot_sql_hash != $GODOT_SQL_HASH ]; then
	echo "Hash check for downloaded 'godot-sqlite' zip failed"
	exit
fi

echo "godot-sqlite hash validated."

# Extract to addons folder
unzip -q  "setup_downloads/godot-sqlite.zip" -d "."

# Delete setup_downloads folder
# rm -r "setup_downloads"
