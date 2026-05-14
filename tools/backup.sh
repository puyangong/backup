#!/bin/bash
# Cross-platform backup script using 7-Zip
# Backup directory is relative to the CURRENT WORKING DIRECTORY where the script is executed

# Get current working directory (where script is invoked)
WORK_DIR="$(pwd)"
BACKUP_DIR="$WORK_DIR/.backup"

# Create backup directory if not exists
mkdir -p "$BACKUP_DIR"

# Detect system and select appropriate 7z binary
SEVEN_ZIP=""
DETECTED_TOOL=""

# Get system info
OS="$(uname -s | tr '[:upper:]' '[:lower:]')"
ARCH="$(uname -m)"

# Tool directory is relative to SCRIPT location (not working directory)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Determine tool directory based on system
case "$OS" in
    linux*)
        if [[ "$ARCH" == *"arm"* ]] || [[ "$ARCH" == *"aarch64"* ]]; then
            TOOL_DIR="$SCRIPT_DIR/7z2600-linux-arm64"
        else
            TOOL_DIR="$SCRIPT_DIR/7z2600-linux-x64"
        fi
        ;;
    darwin*|mac*)
        TOOL_DIR="$SCRIPT_DIR/7z2600-mac"
        ;;
    *)
        TOOL_DIR=""
        ;;
esac

# Priority 1: Local tool directory
if [[ -n "$TOOL_DIR" ]] && [[ -f "$TOOL_DIR/7zz" || -f "$TOOL_DIR/7z" ]]; then
    if [[ -f "$TOOL_DIR/7zz" ]]; then
        SEVEN_ZIP="$TOOL_DIR/7zz"
    else
        SEVEN_ZIP="$TOOL_DIR/7z"
    fi
    DETECTED_TOOL="local $TOOL_DIR"
fi

# Priority 2: System PATH
if [[ -z "$SEVEN_ZIP" ]]; then
    if command -v 7zz &> /dev/null; then
        SEVEN_ZIP="7zz"
        DETECTED_TOOL="system PATH (7zz)"
    elif command -v 7z &> /dev/null; then
        SEVEN_ZIP="7z"
        DETECTED_TOOL="system PATH (7z)"
    fi
fi

# Priority 3: Download if not found
if [[ -z "$SEVEN_ZIP" ]]; then
    echo "No 7-Zip found, downloading..."
    TMP_DIR=$(mktemp -d)
    
    if [[ "$OS" == "darwin"* ]]; then
        # macOS: Download from official site
        curl -L -o "$TMP_DIR/7z-mac.zip" "https://www.7-zip.org/a/7z2408-mac.tar.bz2" 2>/dev/null
        tar -xjf "$TMP_DIR/7z-mac.tar.bz2" -C "$TMP_DIR" 2>/dev/null
        if [[ -f "$TMP_DIR/7zz" ]]; then
            SEVEN_ZIP="$TMP_DIR/7zz"
            chmod +x "$SEVEN_ZIP"
            DETECTED_TOOL="downloaded (mac)"
        fi
    else
        # Linux: Download from official site
        if [[ "$ARCH" == *"arm"* ]] || [[ "$ARCH" == *"aarch64"* ]]; then
            URL="https://www.7-zip.org/a/7z2408-linux-arm64.tar.xz"
        else
            URL="https://www.7-zip.org/a/7z2408-linux-x64.tar.xz"
        fi
        curl -L -o "$TMP_DIR/7z.tar.xz" "$URL" 2>/dev/null
        tar -xJf "$TMP_DIR/7z.tar.xz" -C "$TMP_DIR" 2>/dev/null
        if [[ -f "$TMP_DIR/7zz" ]]; then
            SEVEN_ZIP="$TMP_DIR/7zz"
            chmod +x "$SEVEN_ZIP"
            DETECTED_TOOL="downloaded"
        fi
    fi
    
    # Cleanup temp
    rm -rf "$TMP_DIR"
fi

if [[ -n "$DETECTED_TOOL" ]]; then
    echo "Using 7-Zip from: $DETECTED_TOOL"
fi

# Generate timestamp
DT=$(date '+%Y-%m-%d-%H-%M-%S')

# Shift backups: 10->11, 9->10, ..., 1->2
cd "$BACKUP_DIR" || exit 1
for i in $(seq 10 -1 1); do
    next=$((i + 1))
    if [[ -f "${i}-"*.zip ]]; then
        mv "${i}-"*.zip "${next}-"*.zip 2>/dev/null
    fi
done

# Delete backup #11 (oldest)
rm -f "11-"*.zip 2>/dev/null

# Create new backup #1
BACKUP_FILE="1-${DT}.zip"
echo "Creating backup: $BACKUP_FILE"

# Backup all files and directories (includes empty dirs), excluding .backup
cd "$WORK_DIR" || exit 1

if [[ -n "$SEVEN_ZIP" ]] && [[ -x "$SEVEN_ZIP" || "$SEVEN_ZIP" == "7z" || "$SEVEN_ZIP" == "7zz" ]]; then
    # Use 7z - directly add all items, excluding .backup directory
    echo "Using 7-Zip compression..."
    "$SEVEN_ZIP" a -tzip "$BACKUP_DIR/$BACKUP_FILE" . -xr!.backup -r > /dev/null 2>&1
else
    # Fallback to system zip
    echo "Using system zip..."
    zip -r "$BACKUP_DIR/$BACKUP_FILE" . -x ".backup/*" -x ".backup" > /dev/null 2>&1
fi

echo ""
echo "Backup completed!"
cd "$BACKUP_DIR" || exit 1
ls -1 *.zip 2>/dev/null | sort
