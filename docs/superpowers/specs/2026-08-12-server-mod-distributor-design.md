# Server Mod Distributor Design Specification

**Date:** 2026-08-12  
**Target Script:** [`script/MOD_MANAGER.ps1`](file:///c:/dev/minecraft/script/MOD_MANAGER.ps1)  
**Status:** Approved  

---

## 1. Goal & Context

Provide a zero-friction, 1-click mod distributor script (`MOD_MANAGER.ps1`) for players joining a hosted Minecraft server. Friends running the script will automatically get `ferium.exe` bootstrapped if missing and sync their local `%APPDATA%\.minecraft\mods` folder against a master mod manifest hosted online (or locally).

---

## 2. Architecture & Data Flow

```
[GitHub Gist / Remote URL] (server-mods.txt)
          │
          ▼ (Invoke-RestMethod)
   [MOD_MANAGER.ps1] ──── Checks ────► [Local Ferium Check]
          │                                  │
          │ (If missing: Download zip)       ▼
          │ ◄───────────────────────── [LOCALAPPDATA\Ferium]
          │
          ▼
   [Ferium CLI Profile Sync]
          │
          ▼ (ferium upgrade)
   [%APPDATA%\.minecraft\mods]
```

1. **Auto-Bootstrap Phase**:
   - Checks if `ferium.exe` exists at `$env:LOCALAPPDATA\Ferium\ferium.exe` (or local fallback).
   - If not found, downloads the official GitHub release zip (`https://github.com/the-cursed-modpack/ferium/releases/latest`), extracts `ferium.exe`, and places it in `$env:LOCALAPPDATA\Ferium\`.

2. **Manifest Acquisition**:
   - Configurable `$ManifestUrl` variable at top of script pointing to raw text/Gist URL.
   - If URL is reachable, fetches raw list via `Invoke-RestMethod`.
   - If URL is empty or offline, falls back to reading `server-mods.txt` in the script directory.

3. **Execution & Sync Engine**:
   - Reads mod slugs line-by-line (ignoring comments starting with `#` or blank lines).
   - Injects each mod slug into the Ferium profile using `ferium add <slug>`.
   - Runs `ferium upgrade --output-dir "$env:APPDATA\.minecraft\mods"` to sync binaries directly into Minecraft's mods folder.
   - Displays clear colorized progress and completion feedback (`[SUCCESS] Synced N mods!`).

---

## 3. Interfaces & Components

### 3.1 PowerShell Script (`script/MOD_MANAGER.ps1`)
- **Global Variables**:
  - `$ManifestUrl`: Public raw URL for the mod list (e.g. GitHub Gist).
  - `$FeriumDir`: `$env:LOCALAPPDATA\Ferium`
  - `$FeriumExe`: Join-Path `$FeriumDir` `"ferium.exe"`
  - `$MinecraftModsDir`: `$env:APPDATA\.minecraft\mods`
- **Functions**:
  - `Ensure-FeriumInstalled`: Checks and downloads `ferium.exe` if missing.
  - `Get-ModManifest`: Fetches remote mod list or local fallback.
  - `Sync-ServerMods`: Parses list, adds mods to Ferium, and triggers upgrade.

---

## 4. Error Handling & Edge Cases

- **Network Offline / Invalid URL**: Script falls back gracefully to local `server-mods.txt`. If neither exists, prints a friendly guidance error.
- **Ferium Exit Codes**: Checks `$LASTEXITCODE` for each `ferium add` and `ferium upgrade`. Displays warnings for any individual mod download failures without crashing the entire loop.
- **Existing File Conflicts**: Relies on Ferium's built-in version checking and upgrade capabilities to replace outdated `.jar` files.
