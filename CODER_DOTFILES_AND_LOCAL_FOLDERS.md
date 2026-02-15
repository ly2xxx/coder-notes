# Coder: Dotfiles & Local Folder Access

**Version:** 2026.02.15  
**Topics:** Dotfiles, Local folder mounting, File sync workflows

---

## 🔹 Dotfiles in Coder

### What Are Dotfiles?

**Dotfiles** are personal configuration files for your shell, editor, and development tools:
- `.bashrc` / `.zshrc` — shell configuration
- `.gitconfig` — Git settings
- `.vimrc` / `.nvimrc` — Vim/Neovim config
- `.tmux.conf` — Tmux settings
- etc.

### How Coder Uses Dotfiles

Coder can **automatically clone and apply your dotfiles** to every new workspace you create:

1. **You maintain a Git repo** with your dotfiles (e.g., `github.com/yourusername/dotfiles`)
2. **You add the repo URL** to your Coder profile
3. **When you create a workspace**, Coder:
   - Clones your dotfiles repo
   - Runs your install script (if present)
   - Applies your configs automatically

### Setting Up Dotfiles in Coder

#### Step 1: Create a Dotfiles Repo

**Example structure:**
```
my-dotfiles/
├── .bashrc
├── .gitconfig
├── .vimrc
├── .tmux.conf
└── install.sh  # Optional: Coder runs this automatically
```

**Example `install.sh`:**
```bash
#!/bin/bash
# Symlink dotfiles to home directory
ln -sf ~/dotfiles/.bashrc ~/.bashrc
ln -sf ~/dotfiles/.gitconfig ~/.gitconfig
ln -sf ~/dotfiles/.vimrc ~/.vimrc

# Install additional tools
sudo apt-get update
sudo apt-get install -y vim tmux
```

Make it executable:
```bash
chmod +x install.sh
```

Push to GitHub:
```bash
git init
git add .
git commit -m "Initial dotfiles"
git remote add origin https://github.com/yourusername/dotfiles.git
git push -u origin main
```

#### Step 2: Add Dotfiles to Coder Profile

1. **Log in to Coder** (e.g., https://test.pit-1.try.coder.app)
2. Click your **profile icon** (top-right) → **Settings**
3. Go to **Dotfiles** section
4. Add your repo URL:
   ```
   https://github.com/yourusername/dotfiles
   ```
5. (Optional) Specify install script path: `install.sh`
6. **Save**

#### Step 3: Test on New Workspace

Create a new workspace → Coder will:
1. Clone your dotfiles repo to `~/dotfiles`
2. Run `install.sh` (if present)
3. Apply your configs

**Verify:**
```bash
# SSH into workspace
coder ssh my-workspace

# Check dotfiles applied
ls -la ~/ | grep dotfiles
cat ~/.bashrc
```

---

## 🔹 Local Folder Access in Coder

### The Challenge

When you connect to a Coder workspace from **local VS Code**, you're editing files **on the remote filesystem**. But what if you need to:
- Access workspace files locally (e.g., `/dist` folder for Chrome extension)
- Upload local files to workspace
- Sync bidirectionally

### Solution Options

---

### **Option 1: SSHFS (Mount Remote to Local)** ✅ Recommended

**Mount the Coder workspace folder to your local machine** as a drive.

#### Windows Setup

**Install WinFsp + SSHFS-Win:**
```powershell
winget install -e --id WinFsp.WinFsp
winget install -e --id SSHFS-Win.SSHFS-Win
```

**Mount workspace:**
```powershell
# Get workspace SSH config from Coder
coder config-ssh

# Mount (replace with your workspace name)
sshfs coder.my-workspace:/home/coder/project Z:
```

Now `Z:\` on Windows maps to `/home/coder/project` in the workspace!

**Unmount:**
```powershell
# Right-click Z: drive → Disconnect
# Or via command:
net use Z: /delete
```

#### Linux/macOS Setup

```bash
# Install SSHFS
# macOS:
brew install macfuse sshfs

# Linux (Ubuntu/Debian):
sudo apt-get install sshfs

# Mount
mkdir ~/coder-workspace
sshfs coder.my-workspace:/home/coder/project ~/coder-workspace

# Unmount
fusermount -u ~/coder-workspace  # Linux
umount ~/coder-workspace          # macOS
```

**Pros:**
- Real-time access (appears as local folder)
- Works with any local tools (Chrome, file managers)
- Bidirectional (changes sync both ways)

**Cons:**
- Requires good network connection
- Slightly slower than local files

---

### **Option 2: `rsync` / `scp` (One-way Sync)**

**Copy files between local and workspace.**

#### Using `rsync` (Recommended)

**Local → Workspace:**
```bash
# Sync entire folder
rsync -avz --progress /local/folder/ coder.my-workspace:/remote/folder/

# Sync single file
rsync -avz file.txt coder.my-workspace:/home/coder/project/
```

**Workspace → Local:**
```bash
# Sync entire folder
rsync -avz --progress coder.my-workspace:/remote/folder/ /local/folder/

# Sync single file
rsync -avz coder.my-workspace:/dist/extension.zip ./
```

**Watch mode (auto-sync on change):**
```bash
# Install watchman or use fswatch
fswatch -o /local/folder | xargs -n1 -I{} rsync -avz /local/folder/ coder.my-workspace:/remote/folder/
```

#### Using `scp` (Simple, one-off)

```bash
# Upload to workspace
scp -r /local/folder coder.my-workspace:/remote/folder/

# Download from workspace
scp -r coder.my-workspace:/remote/folder /local/folder/
```

**Pros:**
- Simple, built-in tool
- Works over SSH
- Good for one-off transfers

**Cons:**
- Manual sync (not real-time)
- No automatic change detection

---

### **Option 3: Git (The Coder Way)** ⭐ Best Practice

**Coder's philosophy:** Don't sync files, sync **code via Git**.

**Workflow:**
1. Work in Coder workspace (remote)
2. Commit changes: `git commit -am "update"`
3. Push: `git push`
4. Pull on local machine (if needed): `git pull`

**Advantages:**
- Version control built-in
- No manual sync needed
- Works across any machine
- Coder-native approach

**When to use:**
- Source code development
- Any project already in Git
- Team collaboration

**When NOT to use:**
- Large binary files
- Build artifacts (`/dist`, `/node_modules`)
- Temporary files

---

### **Option 4: VS Code Download/Upload**

**Built-in VS Code feature** when connected via Remote-SSH.

**Download from workspace:**
1. In VS Code, connected to Coder workspace
2. Right-click folder/file in Explorer
3. **Download...**
4. Choose local destination

**Upload to workspace:**
1. Drag-and-drop file into VS Code
2. Or: Terminal → `code /path/to/file` then save

**Pros:**
- No extra tools needed
- Simple for small files
- Works from VS Code

**Cons:**
- Manual process
- Slow for large folders
- No real-time sync

---

### **Option 5: Coder Port Forwarding + HTTP Server**

**Serve workspace files via HTTP** and access locally.

**In workspace:**
```bash
# Serve /dist folder on port 8000
cd /home/coder/project/dist
python3 -m http.server 8000
```

**In local VS Code:**
- **Ports** tab → Forward port 8000
- Access in browser: `http://localhost:8000`

**Download files:**
```bash
# From local machine
wget http://localhost:8000/extension.zip
```

**Pros:**
- No extra tools
- Works through Coder tunnel
- Good for quick downloads

**Cons:**
- Read-only (download only)
- Manual process
- Security (unencrypted)

---

## 📦 Use Case: Chrome Extension Development

**Problem:** Developing a Chrome extension in Coder workspace, but need to test in **local Chrome**.

### Recommended Workflow

#### Option A: SSHFS (Best for active development)

```powershell
# Mount workspace /dist folder locally
sshfs coder.my-workspace:/home/coder/project/dist Z:\extension-dist

# In Chrome:
# chrome://extensions → Load unpacked → Select Z:\extension-dist
```

Changes in workspace `/dist` appear **immediately** in local Chrome!

#### Option B: Build + Download Script

**In workspace, create `sync-dist.sh`:**
```bash
#!/bin/bash
# Build extension
npm run build

# Zip dist folder
cd dist
zip -r ../extension-$(date +%Y%m%d-%H%M%S).zip .
cd ..

echo "Extension built: extension-$(date +%Y%m%d-%H%M%S).zip"
echo "Download from VS Code or use scp"
```

**Download manually** or automate:
```bash
# From local machine
scp coder.my-workspace:/home/coder/project/extension-*.zip ./
```

#### Option C: Git + Local Build

```bash
# In workspace
git add .
git commit -m "update extension"
git push

# On local machine
git pull
npm run build
# Load dist/ in Chrome
```

**Best for:** Stable releases, not active development.

---

## 🛠️ Troubleshooting

### SSHFS Mount Fails (Windows)

**Error:** "Cannot connect to SSHFS"

**Fix:**
1. Ensure WinFsp installed: `winget list WinFsp`
2. Check SSH config: `coder config-ssh`
3. Test SSH connection: `ssh coder.my-workspace`
4. Use explicit path: `sshfs coder.my-workspace:. Z:`

### rsync Permission Denied

**Error:** "rsync: failed to set permissions"

**Fix:**
```bash
# Add --no-perms flag
rsync -avz --no-perms --progress /local/ coder.workspace:/remote/
```

### Slow SSHFS Performance

**Solutions:**
1. Use compression: `sshfs -C coder.workspace:/path Z:`
2. Enable caching: `sshfs -o cache=yes,kernel_cache coder.workspace:/path Z:`
3. Increase buffer: `sshfs -o max_read=131072 coder.workspace:/path Z:`

---

## 💡 Best Practices

1. **Use Git for source code** — cleanest, most reliable
2. **Use SSHFS for build artifacts** — real-time access
3. **Use rsync for large one-off transfers** — fast, efficient
4. **Avoid syncing `node_modules`** — reinstall in workspace
5. **Keep dotfiles in Git** — version control your configs
6. **Use `.gitignore`** — don't sync `.env`, secrets

---

## 📚 Resources

- **Coder Dotfiles Docs:** https://coder.com/docs/admin/users#dotfiles
- **SSHFS Windows:** https://github.com/winfsp/sshfs-win
- **rsync Manual:** https://linux.die.net/man/1/rsync
- **VS Code Remote SSH:** https://code.visualstudio.com/docs/remote/ssh

---

## 🎯 Quick Reference

| Task | Best Method | Command |
|------|-------------|---------|
| **Auto-apply shell configs** | Dotfiles | Add repo in Profile → Dotfiles |
| **Real-time local access** | SSHFS | `sshfs coder.workspace:/path Z:` |
| **One-off file transfer** | scp | `scp file.txt coder.workspace:/path/` |
| **Sync source code** | Git | `git push` / `git pull` |
| **Download build artifacts** | VS Code | Right-click → Download |
| **Continuous sync** | rsync + watch | `fswatch + rsync` |

---

**Happy remote coding! 🚀**
