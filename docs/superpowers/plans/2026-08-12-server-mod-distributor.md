# Server Mod Distributor Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Transform `script/MOD_MANAGER.ps1` into an automated, 1-click server mod distributor featuring Ferium auto-bootstrapping and remote/local manifest synchronization.

**Architecture:** A PowerShell script that auto-downloads `ferium.exe` to `$env:LOCALAPPDATA\Ferium` if missing, fetches the master server mod manifest from a remote URL (or local `server-mods.txt`), injects missing slugs into Ferium, and upgrades mod binaries directly to `%APPDATA%\.minecraft\mods`.

**Tech Stack:** PowerShell 5.1+, Ferium CLI, GitHub Releases API via `Invoke-WebRequest` / `Invoke-RestMethod`.

## Global Constraints

- Target script: `script/MOD_MANAGER.ps1`
- Ferium installation path: `$env:LOCALAPPDATA\Ferium\ferium.exe`
- Target Minecraft output directory: `$env:APPDATA\.minecraft\mods`
- Error handling preference: `$ErrorActionPreference = "Continue"`

---

### Task 1: Ferium Auto-Bootstrap & Path Resolution

**Files:**
- Modify: [`script/MOD_MANAGER.ps1`](file:///c:/dev/minecraft/script/MOD_MANAGER.ps1)
- Create: [`script/server-mods.txt`](file:///c:/dev/minecraft/script/server-mods.txt)

**Interfaces:**
- Consumes: PowerShell `$env:LOCALAPPDATA`
- Produces: Function `Ensure-FeriumInstalled` that guarantees `ferium.exe` exists in `$env:LOCALAPPDATA\Ferium\ferium.exe`.

- [ ] **Step 1: Create default local manifest template**

Create `script/server-mods.txt` with sample mod slugs (e.g. `fabric-api`, `sodium`, `lithium`).

- [ ] **Step 2: Implement dynamic path setup and `Ensure-FeriumInstalled` in `MOD_MANAGER.ps1`**

Replace hardcoded `D:\Downloads\appl` with `$env:LOCALAPPDATA\Ferium`. Write `Ensure-FeriumInstalled` function to auto-download and extract `ferium.exe` from GitHub releases if missing.

- [ ] **Step 3: Test Ferium path validation**

Run script check in PowerShell to verify `Ensure-FeriumInstalled` logic.

- [ ] **Step 4: Commit Task 1**

```bash
git add script/MOD_MANAGER.ps1 script/server-mods.txt
git commit -m "feat: add ferium auto-bootstrap and dynamic path resolution"
```

---

### Task 2: Remote/Local Manifest Fetcher & Sync Engine

**Files:**
- Modify: [`script/MOD_MANAGER.ps1`](file:///c:/dev/minecraft/script/MOD_MANAGER.ps1)

**Interfaces:**
- Consumes: `$ManifestUrl` string, local `server-mods.txt`
- Produces: Function `Get-ModManifest` returning string array of mod slugs; Function `Sync-ServerMods` executing batch `ferium add` and `ferium upgrade`.

- [ ] **Step 1: Implement `Get-ModManifest` function**

Add `Get-ModManifest` to attempt `Invoke-RestMethod` against `$ManifestUrl`. Fall back to reading `server-mods.txt` in script directory if remote fetch fails or URL is empty.

- [ ] **Step 2: Implement `Sync-ServerMods` function**

Add `Sync-ServerMods` to parse mod slugs (ignoring comments `#` and blank lines), run `ferium add <slug>`, and run `ferium upgrade --output-dir "$env:APPDATA\.minecraft\mods"`.

- [ ] **Step 3: Integrate 1-Click Sync into Main Menu**

Add option `0` or `1` for **1-Click Server Mod Sync** as the primary default action in the interactive menu loop.

- [ ] **Step 4: Commit Task 2**

```bash
git add script/MOD_MANAGER.ps1
git commit -m "feat: add remote/local manifest sync engine"
```

---

### Task 3: End-to-End Script Verification

**Files:**
- Modify/Verify: [`script/MOD_MANAGER.ps1`](file:///c:/dev/minecraft/script/MOD_MANAGER.ps1)

**Interfaces:**
- Consumes: Complete `MOD_MANAGER.ps1` workflow.
- Produces: Verified executable script.

- [ ] **Step 1: Test script execution and menu options**

Run `powershell -ExecutionPolicy Bypass -File script/MOD_MANAGER.ps1` to test manifest loading and CLI output.

- [ ] **Step 2: Update documentation (`PROJECT_CONTEXT.md` & `BACKLOG.md`)**

Update `docs/PROJECT_CONTEXT.md` and `docs/BACKLOG.md` reflecting the new 1-click sync and auto-bootstrap features.

- [ ] **Step 3: Commit Task 3**

```bash
git add docs/PROJECT_CONTEXT.md docs/BACKLOG.md
git commit -m "docs: update project context and backlog for mod distributor feature"
```
