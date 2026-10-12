#!/bin/bash

GODOT_SQL_TAG="v4.8"
GODOT_SQL_URL="https://github.com/2shady4u/godot-sqlite/releases/download/${GODOT_SQL_TAG}/addons.zip"
GODOT_SQL_HASH="f81531b5b9f1d4f422e9f882c409701adf197a17f894ca65ee2fa25759c25270"

GDUNIT4_TAG="v6.2.1"
GDUNIT4_URL="https://github.com/godot-gdunit-labs/gdUnit4/archive/refs/tags/${GDUNIT4_TAG}.zip"
GDUNIT4_HASH="ffb48847c46f386bf0c7a716fd68c6dace7d67730775cf7f748adce8ef3ed794"

GIZMO3D_URL="https://github.com/OpenMinerva/Gizmo3D/archive/refs/heads/main.zip"
GIZMO3D_HASH="1d640be27629b622b96db54c8a94834ad18930146f6a41f28128ed47a6e6f4c1"



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


# Download gdUnit4
echo "Downloading 'gdUnit4' tagged '${GDUNIT4_TAG}'"

if [ ! -f "setup_downloads/gdUnit4.zip" ]; then
	curl -sSL -H "Accept: application/octet-stream" -o "setup_downloads/gdUnit4.zip" "${GDUNIT4_URL}" 
fi
# Validate SHA256
downloaded_gdunit4_hash=$(sha256sum "setup_downloads/gdUnit4.zip" | awk '{print $1}' )
echo $downloaded_gdunit4_hash
if [ $downloaded_gdunit4_hash != $GDUNIT4_HASH ]; then
	echo "Hash check for downloaded 'gdUnit4' zip failed"
	exit
fi

echo "gdUnit4 hash validated."

# Extract to addons folder
unzip -q "setup_downloads/gdUnit4.zip" -d "setup_downloads/gdUnit4"
mv setup_downloads/gdUnit4/*/addons/gdUnit4 "addons/"

# Download Gizmo3DScript
echo "Downloading 'Gizmo3DScript'"

# Download Gizmo3DScript
if [ ! -f "setup_downloads/Gizmo3D-main.zip" ]; then
	curl -sSL -H "Accept: application/octet-stream" -o "setup_downloads/Gizmo3D-main.zip" "${GIZMO3D_URL}"
fi

# Validate SHA256
downloaded_gizmo3d_hash=$(sha256sum "setup_downloads/Gizmo3D-main.zip" | awk '{print $1}' )
echo $downloaded_gizmo3d_hash
if [ $downloaded_gizmo3d_hash != $GIZMO3D_HASH ]; then
	echo "Hash check for downloaded 'Gizmo3D' zip failed"
	exit
fi

echo "Gizmo3D hash validated."

# Extract to addons folder
unzip -q  "setup_downloads/Gizmo3D-main.zip" -d "setup_downloads"
mv setup_downloads/Gizmo3D-main/addons/Gizmo3DScript "addons/"



# Delete setup_downloads folder
# rm -r "setup_downloads"
