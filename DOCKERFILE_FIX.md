# Dockerfile Fix - Playwright Template Build Error

## Problem
Build failed with error:
```
Error running legacy build: exit code: 100
```

During package installation step in Coder workspace template.

## Root Causes

1. **`FROM ubuntu`** - Uses latest tag (unpredictable, could be 24.04+)
2. **Old Node.js** - Ubuntu repos ship ancient Node.js/npm versions
3. **`libxshmfence1`** - Package name doesn't exist in newer Ubuntu
4. **Missing packages** - Some dependencies were incomplete

## Solution

### Changes Made

| Before | After | Why |
|--------|-------|-----|
| `FROM ubuntu` | `FROM ubuntu:22.04` | Pin to stable LTS version |
| Ubuntu's nodejs/npm | NodeSource Node.js 20 | Get modern Node.js (required for Playwright) |
| `libxshmfence1` | Removed + added `libnspr4`, `libdbus-1-3`, `libxfixes3` | Correct package names |
| - | `ENV DEBIAN_FRONTEND=noninteractive` | Prevent interactive prompts |
| - | Install `ca-certificates` first | Required for HTTPS downloads |

### Fixed Dockerfile Structure

```dockerfile
FROM ubuntu:22.04

# 1. Prevent prompts
ENV DEBIAN_FRONTEND=noninteractive

# 2. Install certificates (required for HTTPS)
RUN apt-get update && apt-get install -y ca-certificates curl gnupg

# 3. Install modern Node.js from NodeSource
RUN curl -fsSL https://deb.nodesource.com/setup_20.x | bash - \
    && apt-get install -y nodejs

# 4. Install system packages + Playwright dependencies
RUN apt-get update && apt-get install -y \
    [all packages including correct Chromium deps]

# 5. Install Playwright + Chromium
RUN npm install -g playwright@latest \
    && npx playwright install chromium --with-deps
```

## Testing

After updating the Dockerfile:

1. **Re-upload template** to Coder
2. **Create workspace** from template
3. **Verify Playwright:**
   ```bash
   node -e "require('playwright'); console.log('OK')"
   npx playwright --version
   ```

## Why Node.js 20?

- **Playwright requires:** Node.js 16+ (18+ recommended)
- **Ubuntu 22.04 ships:** Node.js 12 (too old!)
- **NodeSource provides:** Latest stable Node.js versions

## Package Reference

Correct Playwright/Chromium dependencies for Ubuntu 22.04:

```
libnss3          # Network Security Services
libnspr4         # Netscape Portable Runtime
libatk1.0-0      # Accessibility Toolkit
libatk-bridge2.0-0
libcups2         # Print support
libdrm2          # Direct Rendering Manager
libdbus-1-3      # Message bus system
libxkbcommon0    # Keyboard handling
libxcomposite1   # X11 compositing
libxdamage1      # X11 damage extension
libxfixes3       # X11 fixes extension
libxrandr2       # X11 resize/rotate
libgbm1          # Graphics Buffer Manager
libasound2       # Audio library
libpango-1.0-0   # Text rendering
libcairo2        # 2D graphics
fonts-liberation # Core fonts
libappindicator3-1
xdg-utils        # Desktop integration
wget             # Download utility
```

## Future-Proofing

To avoid this issue:
- ✅ Always pin Docker base image versions (`ubuntu:22.04` not `ubuntu`)
- ✅ Use NodeSource/official repos for Node.js (not distro packages)
- ✅ Test builds locally before uploading to Coder
- ✅ Document package dependencies

---

*Fixed: 2026-02-16 by Helpful Bob 🤖*
