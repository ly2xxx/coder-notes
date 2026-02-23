# Downloading Files from Coder Workspaces (CLI Only)

When you have command-line-only access to a Coder workspace (no VS Code browser), here are your options for downloading files.

---

## Option 1: Quick Download via SSH Stream (✅ No Setup)

**Best for small one-off files without configuring SSH.**

```bash
# [LOCAL] Download a single file using cat redirection
coder login <your-coder-url>
coder ssh <workspace-name> -- cat /path/to/remote/file > local-file.txt

# Example [LOCAL]
coder login https://service.coder.app
coder ssh workspace-from-build-template00 -- cat filename.txt > filename.txt
```

**Pros:**
- ✅ No setup required
- ✅ Works immediately in any terminal
- ✅ Safe for simple text files

**Cons:**
- ❌ Harder to use for binary files without encoding (base64)
- ❌ No progress bar
- ❌ Manual filename specification required

---

## Option 2: Native SCP/RSYNC (Recommended ✅🚀)

**Best for ongoing work - one-time setup, then use standard powerful tools.**

### Setup (One-time) [LOCAL]
```bash
# Configure SSH
coder config-ssh

# This adds entries to ~/.ssh/config
```

### Usage (After setup) [LOCAL]
**⚠️ IMPORTANT: Run these commands in your LOCAL terminal, NOT inside the Coder workspace.**

```bash
# Now use standard scp
scp workspace-from-build-template00.coder:/path/to/file ~/Downloads/

# Use rsync for efficient sync
rsync -avz workspace-from-build-template00.coder:/path/to/dir/ ~/local-dir/

# Download with progress
rsync -avz --progress my-workspace.coder:~/project/ ~/backup/

# Download only newer files
rsync -avzu dev-workspace.coder:/data/ ~/local-data/
```

**Pros:**
- ✅ Fastest transfers
- ✅ Use familiar scp/rsync commands
- ✅ Better for repeated operations
- ✅ Rsync supports incremental sync

**Cons:**
- ❌ Requires one-time setup

---

## Option 3: SSH + Tar Stream (For Large Directories 📦)

**Best for downloading entire directories or multiple files efficiently**

```bash
# Stream tar archive from workspace to local
coder ssh my-workspace -- "tar czf - /path/to/directory" > local-backup.tar.gz

# Download and extract in one step
coder ssh my-workspace -- "tar czf - ~/project" | tar xzf - -C ~/Downloads/

# Download single file via cat
coder ssh my-workspace -- cat /path/to/file.txt > local-file.txt

# Download with filtering
coder ssh my-workspace -- "tar czf - ~/logs/*.log" > logs-$(date +%Y%m%d).tar.gz

# Exclude certain patterns
coder ssh my-workspace -- "tar czf - --exclude='node_modules' --exclude='.git' ~/project" > project.tar.gz
```

**Pros:**
- ✅ Very efficient for large directories
- ✅ Can filter/exclude files
- ✅ Compressed transfer
- ✅ Single command

**Cons:**
- ❌ More complex syntax
- ❌ Creates temporary archive

---

## Option 4: Port-Forward + HTTP Server (For Browsing Files 🌐)

**Best when you want to browse/preview files before downloading**

### 1. In the Workspace [WORKSPACE]
**Open a terminal and SSH into your workspace first.**

```bash
# SSH into workspace
coder ssh workspace-from-build-template00

# Start HTTP server INSIDE the workspace
python3 -m http.server 8080
```
*(Leave this terminal window open and running)*

### 2. On your Laptop/PC [LOCAL]
**Open a SECOND, fresh terminal on your local machine.**

```bash
# Port-forward FROM your local machine TO the workspace
coder port-forward workspace-from-build-template00 --tcp 8088:8080
```
*(Leave this terminal window open and running)*

### On your local machine (separate terminal): [LOCAL]
```bash
# Port-forward
coder port-forward my-workspace --tcp 8000:8000

# Download via browser
# Open: http://localhost:8000

# Or download with curl
curl http://localhost:8000/file.txt -o file.txt

# Download with wget
wget http://localhost:8000/data.csv

# Forward remote port 8080 to local port 8088 [LOCAL]
coder port-forward workspace-from-build-template00 --tcp 8088:8080
```

**Pros:**
- ✅ Browse directory structure
- ✅ Preview files before downloading
- ✅ Works with any HTTP client
- ✅ Good for non-technical users

**Cons:**
- ❌ Requires two terminal sessions
- ❌ Manual server startup

---

## Quick Reference Examples

### Single File
```bash
# Option A: SSH Stream (One-off)
# (Run in local terminal)
coder ssh dev-workspace -- cat ~/report.pdf > ~/Desktop/report.pdf

# Option B: Standard scp (After one-time coder config-ssh)
# (Run in local terminal)
scp dev-workspace.coder:~/report.pdf ~/Desktop/
```

### Entire Directory
```bash
# Option A: Tar Stream (One-off)
# (Run in local terminal)
coder ssh my-workspace -- "tar czf - ~/project" | tar xzf - -C ~/Downloads/

# Option B: Rsync (After one-time coder config-ssh)
# (Run in local terminal)
rsync -avz my-workspace.coder:~/project/ ~/local-project/
```

### Multiple Files (Wildcards)
```bash
# Download all CSVs
coder ssh my-workspace -- "tar czf - ~/data/*.csv" > data.tar.gz
tar xzf data.tar.gz

# Download logs from last week
coder ssh my-workspace -- "find ~/logs -mtime -7 -name '*.log' | tar czf - -T -" > recent-logs.tar.gz
```

### Large Directory Sync
```bash
# One-time setup
coder config-ssh

# Efficient incremental backup
rsync -avzu --progress my-workspace.coder:~/important-data/ ~/backups/workspace-data/
```

---

## Decision Tree

```
Need to download files?
│
├─ Single file once?
│  └─ Use: coder ssh + cat redirection
│
├─ First time or recursive?
│  └─ Use: SSH + tar stream
│
├─ Regular/Bulk work?
│  └─ Use: coder config-ssh + scp/rsync (Fastest)
│
├─ Entire project backup?
│  └─ Use: SSH + tar stream
│
└─ Want to browse files first?
   └─ Use: Port-forward + HTTP server
```

---

## Tips & Tricks

### 1. Download with Timestamp
```bash
coder ssh my-workspace -- cat ~/backup.sql > ~/Downloads/backup-$(date +%Y%m%d).sql
```

### 2. Download Multiple Specific Files
```bash
coder ssh my-workspace -- "tar czf - file1.txt file2.csv dir/file3.json" > files.tar.gz
```

### 3. Check File Before Downloading
```bash
# Check file size
coder ssh my-workspace -- ls -lh /path/to/large-file.zip

# Check disk usage of directory
coder ssh my-workspace -- du -sh /path/to/directory
```

### 4. Resume Interrupted Downloads (with rsync)
```bash
# Rsync can resume interrupted transfers
rsync -avz --partial my-workspace.coder:/large-file.zip ~/Downloads/
```

### 5. Parallel Downloads (Multiple Files)
```bash
# Download files in parallel using background jobs
# Download multiple files sequentially via SSH
coder ssh workspace -- cat file1.txt > file1.txt; coder ssh workspace -- cat file2.txt > file2.txt
wait  # Wait for all downloads to complete
```

---

## Troubleshooting

### "Permission denied"
```bash
# Check file permissions on workspace
coder ssh my-workspace -- ls -la /path/to/file

# Fix if needed
coder ssh my-workspace -- chmod 644 /path/to/file
```

### "No such file or directory"
```bash
# List directory contents
coder ssh my-workspace -- ls -la /path/to/

# Find file
coder ssh my-workspace -- find ~ -name "filename.txt"
```

### Slow transfers
```bash
# Use compression for text files
coder ssh my-workspace -- "tar czf - /path" > local.tar.gz

# Or configure SSH compression
# Add to ~/.ssh/config:
# Host coder.*
#     Compression yes
```

### Windows Git Bash Issues
If you are on Windows using Git Bash, you might see an error like `C:Users...coder.exe: command not found`. This happens because Git Bash mistakenly strips the backslashes from the `ProxyCommand` path generated by `coder config-ssh`.
- **Solution 1:** Use PowerShell or Command Prompt for `scp` commands.
- **Solution 2:** Open `~/.ssh/config` and change the Windows path `C:\path\to\coder.exe` to use forward slashes `/` and wrap it in quotes (`"C:/path/to/coder.exe"`), or just use `coder.exe` if it's securely in your PATH.
- **Note:** `rsync` is not installed by default on Windows natively.

---

## Best Practices

1. **Use `coder config-ssh` for regular work** - Set it up once, then use standard tools
2. **Use tar streams for large directories** - More efficient than recursive scp
3. **Use rsync for incremental backups** - Only transfers changed files
4. **Compress before transfer** - Faster for large text files
5. **Check file size first** - Avoid accidentally downloading huge files

---

## Related Commands

```bash
# List workspaces
coder list

# Check workspace status
coder show my-workspace

# SSH into workspace
coder ssh my-workspace

# Execute command without interactive shell
coder ssh my-workspace -- command

# Upload files (Opposite of download)
# Needs config-ssh first, then use standard scp:
# (Run in local terminal)
scp /local/file workspace.coder:/remote/path
```

---

**Last Updated:** 2026-02-23  
**For Coder CLI Version:** v2+

---

## Additional Resources

- [Coder Documentation](https://coder.com/docs)
- [Coder CLI Reference](https://coder.com/docs/cli)
- [SSH Config Guide](https://coder.com/docs/cli/ssh)
