#!/bin/bash

# Source and destination paths
SOURCE="/home/m/proj"
DESTINATION="/home/m/junk/synctest"

# Exclude patterns (e.g., env folders)
EXCLUDE=(
  --exclude='**/env'"
  --exclude='env/'"
)
# Create log file with timestamp
LOG_FILE="$DESTINATION/sync_$(date +'%Y-%m-%d_%H-%M-%S').log"
echo "Removing files in $DESTINATION"
rm -rf $DESTINATION/*
# Rsync command with exclusions and logging
echo "Starting backup at $(date)" >"$LOG_FILE"
rsync -avz --progress $EXCLUDE "$SOURCE/" "$DESTINATION/" >>"$LOG_FILE" 2>&1

echo "Backup completed at $(date)" >>"$LOG_FILE"
