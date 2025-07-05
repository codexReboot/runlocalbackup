#!/bin/bash

USER="schalk"
SRC="/home/$USER"
BACKUP_BASE="/home/$USER/Backups"
LOG_DIR="$BACKUP_BASE/logs"
CSV_LOG="$BACKUP_BASE/backup_history.csv"
BACKUP_NUM_FILE="$BACKUP_BASE/backup_number.txt"
TIMESTAMP=$(date +"%Y-%m-%d_%H-%M")
BACKUP_DATE=$(date +"%Y-%m-%d")
START_TIME=$(date +%s)
BACKUP_DIR="$BACKUP_BASE/backup-$TIMESTAMP"

mkdir -p "$BACKUP_DIR" "$LOG_DIR"

# Ask for confirmation
zenity --question --title="Local Backup" --text="A new backup will start now. Proceed?" 2>/dev/null || exit 1

# Determine backup number
if [[ -f "$BACKUP_NUM_FILE" ]]; then
    BACKUP_NUM=$(<"$BACKUP_NUM_FILE")
    BACKUP_NUM=$((BACKUP_NUM + 1))
else
    BACKUP_NUM=1
fi
echo "$BACKUP_NUM" > "$BACKUP_NUM_FILE"

RSYNC_LOG=$(mktemp)

# Run rsync silently and capture output
rsync -a --stats --ignore-errors \
  --exclude=".cache/" \
  --exclude="Downloads/" \
  --exclude=".local/share/Trash/" \
  --exclude="**/node_modules/" \
  --exclude="Backups/" \
  "$SRC/" "$BACKUP_DIR/" > "$RSYNC_LOG" 2>&1

# Parse rsync stats
RAW_TRANSFERRED=$(grep "Number of regular files transferred:" "$RSYNC_LOG" | awk -F: '{print $2}' | tr -d ' ')
RAW_SCANNED=$(grep "Number of files:" "$RSYNC_LOG" | sed -E 's/Number of files:[[:space:]]*([0-9,]+).*/\1/' | tr -d ' ')

FILES_TRANSFERRED=$(echo "$RAW_TRANSFERRED" | tr -d ',' | tr -d '\r')
FILES_SCANNED=$(echo "$RAW_SCANNED" | tr -d ',' | tr -d '\r')
FILES_TRANSFERRED=${FILES_TRANSFERRED:-0}
FILES_SCANNED=${FILES_SCANNED:-0}

FILES_TRANSFERRED_HR=$(printf "%'d" "$FILES_TRANSFERRED")
FILES_SCANNED_HR=$(printf "%'d" "$FILES_SCANNED")

# Get backup size
SIZE_HUMAN=$(du -sh "$BACKUP_DIR" 2>/dev/null | cut -f1)

# Time elapsed
END_TIME=$(date +%s)
ELAPSED=$((END_TIME - START_TIME))
ELAPSED_HR=$(printf '%02d:%02d:%02d' $((ELAPSED/3600)) $((ELAPSED%3600/60)) $((ELAPSED%60)))

# Delete oldest if more than 4 backups
BACKUPS=($(find "$BACKUP_BASE" -maxdepth 1 -type d -name "backup-*" | sort))
DELETED_BACKUP=""
if (( ${#BACKUPS[@]} > 4 )); then
    OLDEST="${BACKUPS[0]}"
    rm -rf "$OLDEST"
    OLD_LOG="$LOG_DIR/$(basename "$OLDEST").log"
    [[ -f "$OLD_LOG" ]] && rm "$OLD_LOG"
    DELETED_BACKUP="$OLDEST"
fi

# Write log
SUMMARY_LOG="$LOG_DIR/backup-$TIMESTAMP.log"
echo "=====  📝 Backup Summary: $BACKUP_DATE  =====" > "$SUMMARY_LOG"
echo "" >> "$SUMMARY_LOG"
echo "🔢 Backup number:      $BACKUP_NUM" >> "$SUMMARY_LOG"
echo "📦 Backup location:    $BACKUP_DIR" >> "$SUMMARY_LOG"
echo "📁 Files copied:       $FILES_TRANSFERRED_HR" >> "$SUMMARY_LOG"
echo "📂 Files scanned:      $FILES_SCANNED_HR" >> "$SUMMARY_LOG"
echo "📀 Backup size:        $SIZE_HUMAN" >> "$SUMMARY_LOG"
echo "⏱️  Elapsed time:       $ELAPSED_HR" >> "$SUMMARY_LOG"
[[ -n "$DELETED_BACKUP" ]] && echo "🗑️  Deleted old backup: $DELETED_BACKUP" >> "$SUMMARY_LOG"
echo "✅ Status:             Completed" >> "$SUMMARY_LOG"
echo "" >> "$SUMMARY_LOG"
echo "==========  🎉 Backup Successful  ==========" >> "$SUMMARY_LOG"
# Append to CSV
if [ ! -f "$CSV_LOG" ]; then
    echo "Number,Date,Time,BackupPath,Size,FilesCopied,FilesScanned,Elapsed,DeletedBackup" > "$CSV_LOG"
fi
echo "$BACKUP_NUM,$BACKUP_DATE,$TIMESTAMP,$BACKUP_DIR,$SIZE_HUMAN,$FILES_TRANSFERRED,$FILES_SCANNED,$ELAPSED_HR,$DELETED_BACKUP" >> "$CSV_LOG"

# Show completion message
zenity --info --title="Backup Completed" --text="✅ Backup complete! See terminal or $SUMMARY_LOG for summary." 2>/dev/null

# Print only the summary to terminal
cat "$SUMMARY_LOG"

# Cleanup
rm "$RSYNC_LOG"