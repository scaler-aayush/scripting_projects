#!/bin/bash

# Configuration
LOG_DIR="/var/log/nginx"
ARCHIVE_DIR="/var/log/archives"
ARCHIVE_NAME="nginx_logs_$(date +%Y%m%d).tar.gz"

# Verify log directory exists
if [ ! -d "$LOG_DIR" ]; then
    echo "Error: Log directory $LOG_DIR not found"
    exit 1
fi

# Ensure archive directory exists
mkdir -p "$ARCHIVE_DIR"

# Archive logs
echo "Archiving logs to $ARCHIVE_DIR/$ARCHIVE_NAME..."
tar -czf "$ARCHIVE_DIR/$ARCHIVE_NAME" -C "$LOG_DIR" .

# Verify archive
if [ -f "$ARCHIVE_DIR/$ARCHIVE_NAME" ]; then
    echo "Archive created successfully"
else
    echo "Error: Archive creation failed"
    exit 1
fi