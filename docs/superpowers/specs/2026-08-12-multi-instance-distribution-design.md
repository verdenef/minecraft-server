# Multi-Instance & Git-Ignored Configuration Design Specification

**Date:** 2026-08-12  
**Target Script:** [`script/MOD_MANAGER.ps1`](file:///c:/dev/minecraft/script/MOD_MANAGER.ps1)  
**Status:** Approved  

---

## 1. Goal & Requirements

Support multi-instance management (e.g. `server` instance vs `main` singleplayer instance) on the host machine while keeping personal path overrides git-ignored (`config.json`). Ensure zero setup for friends downloading the script (auto-defaulting to `%APPDATA%\.minecraft\mods`).

---

## 2. Architecture & Data Schema

### 2.1 `.gitignore` Entry
- Add `config.json` to `.gitignore` so user-specific local instance paths are never committed to Git.

### 2.2 Configuration Schema (`script/config.json`)
```json
{
  "active_profile": "server",
  "profiles": {
    "server": "C:\\Users\\Red\\AppData\\Roaming\\.minecraft\\instances\\64290aca06184fb6b59be8d2ef380ff5\\mods",
    "main": "%APPDATA%\\.minecraft\\mods"
  }
}
```

---

## 3. Component Design & Functions

1. **`Get-ScriptConfig`**:
   - Resolves `config.json` alongside `$PSScriptRoot`.
   - If `config.json` does not exist: auto-creates it with default `active_profile = "main"` pointing to `$env:APPDATA\.minecraft\mods`.
   - Returns `$script:MinecraftMods` for the currently selected `active_profile`.

2. **`Switch-ActiveProfile`**:
   - Cycles through available profile keys in `config.json` (e.g. `server` $\leftrightarrow$ `main`).
   - Updates `active_profile` in `config.json` and refreshes `$script:MinecraftMods`.

3. **Menu Integration**:
   - Header banner displays: `Active Profile: [server] -> C:\...\mods`
   - Option `2`: `🔄 Switch Target Instance Profile [server / main]`
   - Option `1`: `⚡ 1-Click Server Mod Sync` (syncs to currently active profile).

---

## 4. Safety & Data Protection

- **No Overwriting Configs**: Ferium operates exclusively on `--output-dir <path>` for `.jar` files.
- **Instance Isolation**: Syncing `server` profile never modifies `.minecraft\mods` or other launcher folders.
