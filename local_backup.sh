#!/bin/bash
# -----------------------------------
# CONFIGURATION
# -----------------------------------
USER="schalk"
SRC="/home/$USER"
BACKUP_BASE="/home/$USER/Backups"
COUNTER_FILE="$BACKUP_BASE/backup_counter.txt"
SUMMARY_FILE="$BACKUP_BASE/backup_summary.csv"
TIMESTAMP=$(date +"%Y-%m-%d_%H-%M")

# -----------------------------------
# INITIALIZE BACKUP NUMBER
# -----------------------------------
mkdir -p "$BACKUP_BASE"
if [ ! -f "$COUNTER_FILE" ]; then
    echo "1" > "$COUNTER_FILE"
fi

BACKUP_NUMBER=$(cat "$COUNTER_FILE")
NEXT_BACKUP_NUMBER=$((BACKUP_NUMBER + 1))
echo "$NEXT_BACKUP_NUMBER" > "$COUNTER_FILE"

BACKUP_DIR="$BACKUP_BASE/backup-$TIMESTAMP"
LOG_FILE="$BACKUP_BASE/backup-$TIMESTAMP.log"
NUM_BACKUPS_TO_KEEP=4

# -----------------------------------
# INITIATE LOGGING
# -----------------------------------
exec > >(tee -a "$LOG_FILE") 2>&1
echo "=== Backup started at $(date) ==="
echo "📦 This is backup number: $BACKUP_NUMBER"

# -----------------------------------
# SHOW START NOTIFICATION
# -----------------------------------
if command -v notify-send >/dev/null 2>&1; then
  notify-send "💾 Backup #$BACKUP_NUMBER Started" "Started at $TIMESTAMP"
fi

# -----------------------------------
# START TIMER (outside subshell!)
# -----------------------------------
START_TIME=$(date +%s)

# -----------------------------------
# ZENITY PROGRESS INTERFACE
# -----------------------------------
(
  echo "10"; echo "# Step 1 of 5: Preparing..." ; sleep 1

  if [ ! -d "$SRC" ]; then
      echo "# ERROR: Source directory missing."; sleep 1; echo "100"
      exit 1
  fi

  echo "30"; echo "# Step 2 of 5: Creating backup folder..." ; sleep 1
  mkdir -p "$BACKUP_DIR" || { echo "# ERROR: Can't create backup directory."; echo "100"; exit 1; }

  echo "50"; echo "# Step 3 of 5: Backing up files..." ; sleep 1

  rsync -a --info=progress2 --ignore-errors \
    --exclude=".cache/" \
    --exclude="Downloads/" \
    --exclude=".local/share/Trash/" \
    --exclude="**/node_modules/" \
    --exclude="Backups/" \
    "$SRC/" "$BACKUP_DIR/"
  RSYNC_STATUS=$?

  if [ $RSYNC_STATUS -ne 0 ]; then
    echo "# ERROR: rsync failed."
    echo "100"
    exit 1
  fi

  echo "80"; echo "# Step 4 of 5: Cleaning up old backups..." ; sleep 1

  cd "$BACKUP_BASE" || exit 1
  OLD_BACKUPS=$(ls -dt backup-* | tail -n +$((NUM_BACKUPS_TO_KEEP + 1)))
  [ -n "$OLD_BACKUPS" ] && echo "$OLD_BACKUPS" | xargs -d '\n' rm -rf --

  echo "100"; echo "# Step 5 of 5: Done!"
  sleep 1

) | zenity --progress --title="Backup in Progress" \
  --percentage=0 --width=450 --height=100 \
  --auto-close --auto-kill

# -----------------------------------
# IF USER CANCELED
# -----------------------------------
if [ $? -ne 0 ]; then
  echo "⚠️ Backup was canceled by user."
  rm -rf "$BACKUP_DIR"
  echo "Deleted incomplete backup folder: $BACKUP_DIR"

  [ ! -f "$SUMMARY_FILE" ] && echo "Backup #,Date/Time,Duration (H:M:S),Files,Size,Status" > "$SUMMARY_FILE"
  echo "$BACKUP_NUMBER,$TIMESTAMP,00:00:00,0,0,Canceled" >> "$SUMMARY_FILE"

  notify-send -u critical "⚠️ Backup Canceled" "Backup #$BACKUP_NUMBER was canceled and deleted."
  echo "=== Backup canceled ==="
  exit 1
fi

# -----------------------------------
# FINALIZE & SUMMARIZE
# -----------------------------------
END_TIME=$(date +%s)
DURATION=$((END_TIME - START_TIME))

# Format duration as HH:MM:SS
HOURS=$((DURATION / 3600))
MINUTES=$(((DURATION % 3600) / 60))
SECONDS=$((DURATION % 60))
FORMATTED_DURATION=$(printf "%02d:%02d:%02d" $HOURS $MINUTES $SECONDS)

# File count with thousands separator
FILE_COUNT=$(find "$BACKUP_DIR" -type f | wc -l)
FILE_COUNT_HUMAN=$(printf "%'d" "$FILE_COUNT")
SIZE_HUMAN=$(du -sh "$BACKUP_DIR" | cut -f1)

# Update CSV summary log
[ ! -f "$SUMMARY_FILE" ] && echo "Backup #,Date/Time,Duration (H:M:S),Files,Size,Status" > "$SUMMARY_FILE"
echo "$BACKUP_NUMBER,$TIMESTAMP,$FORMATTED_DURATION,$FILE_COUNT,$SIZE_HUMAN,Completed" >> "$SUMMARY_FILE"

# Print summary to log
echo ""
echo "=== Backup Summary ==="
echo "📦 Backup number:    $BACKUP_NUMBER"
echo "🕒 Elapsed time:     $FORMATTED_DURATION (hh:mm:ss)"
echo "📁 Files backed up:  $FILE_COUNT_HUMAN"
echo "📦 Total size:       $SIZE_HUMAN"
echo "✅ Status:           Completed"

# Final desktop notification
notify-send "✅ Backup #$BACKUP_NUMBER Complete" \
  "Finished in $FORMATTED_DURATION — $FILE_COUNT_HUMAN files, $SIZE_HUMAN"

echo "=== Backup script finished ==="