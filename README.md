# 🛡️ Run Local Backup Script for Linux

This is a robust and user-friendly Bash script developed specifically for Linux systems such as Ubuntu. It automates versioned backups of your home directory (`/home/<user>`) into a local Backups/ folder.

Designed for developers and professionals, the script features:

- ✅ Progress indicators with a graphical interface (zenity)
- ✅ Desktop notifications (notify-send)
- ✅ Intelligent backup rotation (keeps the last N versions)
- ✅ Comprehensive logging and backup summaries
- ✅ Human-readable reporting of size, file count, and duration

---

## ✨ Features

- 🧠 Tracks and numbers each backup
- 📁 Backups include everything except cache, downloads, and trash
- 🔁 Keeps only the latest 4 backups (older ones are deleted)
- 📊 Shows progress with Zenity GUI
- 🔔 Desktop notifications on start, cancel, and finish
- 📋 Log file and CSV summary report
- 💥 Detects cancellation and removes incomplete backups

---

## 📦 Backup Location

Backups are saved under:

```
/home/<user>/Backups/backup-YYYY-MM-DD_HH-MM
```

Each backup folder contains a full snapshot of the home directory (excluding specific folders).

---

## 📋 Exclusions

The script excludes the following to speed up the backup and avoid redundant files:

- `.cache/`
- `Downloads/`
- `.local/share/Trash/`
- All `node_modules/` folders
- The `Backups/` directory itself

---

## 🔧 Installation

1. **Place the script** in `~/bin/local_backup.sh`
2. **Make it executable:**
   ```bash
   chmod +x ~/bin/local_backup.sh
   ```
3. **Create an alias** by adding this to `~/.bashrc` or `~/.zshrc`:
   ```bash
   alias runlocalbackup='~/bin/local_backup.sh'
   ```
4. **Reload your shell config:**
   ```bash
   source ~/.bashrc
   ```

Now you can run your backup from anywhere using:

```bash
runlocalbackup
```

---

## 🧪 Example Output

```bash
📦 Backup number:    4
🕒 Elapsed time:     00:02:34 (hh:mm:ss)
📁 Files backed up:  62,382
📦 Total size:       5.8G
✅ Status:           Completed
```

---

## 📑 Log Files

- Individual logs: `/home/<user>/Backups/backup-YYYY-MM-DD_HH-MM.log`
- Summary CSV: `/home/<user>/Backups/backup_summary.csv`
- Backup number tracker: `/home/<user>/Backups/backup_counter.txt`

---

## 🗑️ Canceling a Backup

If you click "Cancel" on the Zenity progress bar:
- The backup is aborted
- The incomplete folder is deleted
- You get a critical desktop notification
- The event is logged in the summary file as "Canceled"

---

## 🛠️ Dependencies

Ensure the following are installed:

- `rsync`
- `zenity`
- `notify-send` (usually comes with your desktop environment)

Install missing ones via:

```bash
sudo apt install rsync zenity libnotify-bin
```

---

## 🧩 TODO / Ideas

- Add remote backup option (e.g. USB or NAS)
- Support cloud syncing (e.g. rclone)
- Add checksum verification
- GUI to configure exclusions and retention

---

## 🧑‍💻 Author

### ✍️ Author

**Schalk van Dyk t/a codexReboot**  
- 🌐 [Website](https://schalkvandyk.com)  
- 💼 [GitHub](https://github.com/codexReboot)  
- 👔 [LinkedIn](https://www.linkedin.com/in/codexreboot/) 
- 💬 [Facebook](https://facebook.com/codexReboot) 
- 🐦 [X (Twitter)](https://twitter.com/codexReboot)
- 🧪 [CodePen](https://codepen.io/codexReboot)    
- 📧 Email: `schalk [at] schalkvandyk [dot] com`
