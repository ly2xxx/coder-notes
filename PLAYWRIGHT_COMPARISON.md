# Playwright Installation: Template vs Dotfiles

## Quick Comparison

| Aspect | Template (Dockerfile) | Dotfiles (install.sh) |
|--------|----------------------|----------------------|
| **When installed** | Image build time | First workspace start |
| **Installation time** | Once (reused for all workspaces) | Every new workspace |
| **Reliability** | High (fails at build) | Medium (might fail at runtime) |
| **Disk usage** | Shared across workspaces | Per-workspace duplication |
| **Size impact** | ~400MB in base image | ~400MB per workspace |
| **User control** | None (admin decides) | Full (user can modify) |
| **Best for** | Team requirement | Personal experimentation |

---

## Template Approach (RECOMMENDED)

**File:** `template-dotfiles/build/Dockerfile`

### Advantages ✅
- **One-time cost:** Install once, use everywhere
- **Instant availability:** Ready when workspace starts
- **Consistent:** Same version for all users
- **Reliable:** Build fails early if something's wrong
- **Efficient:** Shared image layer across all workspaces
- **No sudo needed:** Installed system-wide during build

### Disadvantages ❌
- **Requires admin:** Can't change without rebuilding template
- **Heavier base image:** Everyone gets it (even if not needed)
- **Slower builds:** Template build takes longer
- **Less flexible:** Can't easily test different versions

### Code Added to Dockerfile:
```dockerfile
# Node.js (required for Playwright)
nodejs \
npm \
# Playwright system dependencies for Chromium
libnss3 \
libatk1.0-0 \
libatk-bridge2.0-0 \
libcups2 \
libdrm2 \
libxkbcommon0 \
libxcomposite1 \
libxdamage1 \
libxrandr2 \
libgbm1 \
libasound2 \
libpango-1.0-0 \
libcairo2 \
libxshmfence1 \
fonts-liberation \
libappindicator3-1 \
xdg-utils \

# Install Playwright globally and Chromium browser
RUN npm install -g playwright \
    && npx playwright install chromium --with-deps
```

---

## Dotfiles Approach

**File:** `dotfiles-example/install.sh`

### Advantages ✅
- **User control:** Each user decides if they want it
- **Flexible:** Easy to update or change versions
- **Lighter base:** Template stays lean
- **Experimentation:** Test different configs without admin

### Disadvantages ❌
- **Slow startup:** First workspace takes 5-10 min longer
- **Duplicated:** Every workspace installs separately
- **Reliability issues:** Might fail mid-install
- **Network dependent:** Needs good connection at workspace creation
- **Wasted resources:** Multiple 400MB Chromium copies

### Code Added to install.sh:
```bash
# Install Playwright with Chromium
echo "🎭 Installing Playwright with Chromium..."

# Check/install Node.js
if ! command -v node &> /dev/null; then
    sudo apt-get update
    sudo apt-get install -y nodejs npm
fi

# Install system dependencies
if command -v apt-get &> /dev/null; then
    sudo apt-get install -y \
        libnss3 libatk1.0-0 libatk-bridge2.0-0 \
        libcups2 libdrm2 libxkbcommon0 \
        libxcomposite1 libxdamage1 libxrandr2 \
        libgbm1 libasound2 libpango-1.0-0 \
        libcairo2 fonts-liberation xdg-utils
fi

# Install Playwright + Chromium
sudo npm install -g playwright
npx playwright install chromium --with-deps
```

---

## Recommendation 🎯

**Use Template approach** if:
- It's a workspace requirement (not optional)
- Multiple users need the same setup
- You want reliability and consistency
- Workspace startup speed matters

**Use Dotfiles approach** if:
- You're experimenting/testing
- Only you need Playwright (not team-wide)
- Template is locked and you can't modify it
- You want version flexibility

---

## Hybrid Approach (Best of Both)

You can also do BOTH:
1. **Template:** Install Node.js + system dependencies (lightweight)
2. **Dotfiles:** Install Playwright + Chromium (user choice)

This gives users the ability to install Playwright quickly (deps already there) without forcing Chromium on everyone.

**Modified Dockerfile (hybrid):**
```dockerfile
# Install modern Node.js from NodeSource
RUN curl -fsSL https://deb.nodesource.com/setup_20.x | bash - \
    && apt-get install -y nodejs

# Install Playwright system dependencies (but not Playwright itself)
RUN apt-get update \
    && apt-get install -y \
    libnss3 libnspr4 libatk1.0-0 libatk-bridge2.0-0 \
    libcups2 libdrm2 libdbus-1-3 libxkbcommon0 libxcomposite1 \
    libxdamage1 libxfixes3 libxrandr2 libgbm1 libasound2 \
    && rm -rf /var/lib/apt/lists/*
```

Users can then `npm install -g playwright` + `npx playwright install chromium` in their dotfiles if they want it.

---

## Testing Your Changes

**Template approach:**
```bash
cd C:\code\coder-notes\template-dotfiles
docker build -t coder-playwright:latest -f build/Dockerfile build/
docker run -it coder-playwright:latest npx playwright --version
```

**Dotfiles approach:**
```bash
cd C:\code\coder-notes\dotfiles-example
bash install.sh
```

---

*Updated: 2026-02-16 by Helpful Bob 🤖*
