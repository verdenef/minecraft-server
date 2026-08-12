# Project Context: Ferium Minecraft Mod Manager

## Overview
This repository contains management tools for maintaining Minecraft client mods and modpacks using [Ferium](https://github.com/the-cursed-modpack/ferium), a fast CLI manager supporting Modrinth and CurseForge.

The central component is the interactive PowerShell script located at [`script/MOD_MANAGER.ps1`](file:///c:/dev/minecraft/script/MOD_MANAGER.ps1).

---

## Environment & Path Configuration

- **Ferium Directory**: `$env:LOCALAPPDATA\Ferium` (auto-created)
- **Ferium Executable**: `$env:LOCALAPPDATA\Ferium\ferium.exe` (auto-downloaded from GitHub releases if missing)
- **Instance Directory Override**: Configurable `$script:InstanceDir` (e.g. `C:\Users\Red\AppData\Roaming\.minecraft\instances\64290aca06184fb6b59be8d2ef380ff5`). Defaults to standard `%APPDATA%\.minecraft` if unconfigured/missing.
- **Target Minecraft Mods**: `$script:MinecraftMods` (`<InstanceDir>\mods` or `%APPDATA%\.minecraft\mods`)
- **Manifest URL**: Configurable `$script:ManifestUrl` (defaults to local `script/server-mods.txt` fallback)
- **Target Loader / Version**: Fabric (Profile reference: Fabric 26.2)
- **PowerShell Error Preference**: `$ErrorActionPreference = "Continue"`

---

## Script Architecture & Functionality

The interactive menu loop (`MOD_MANAGER.ps1`) provides 9 operational workflows:

| Option | Operation | Ferium Command / Logic | Description |
| :--- | :--- | :--- | :--- |
| **1** | **1-Click Server Mod Sync** | `Get-ModManifest` + `ferium add` + `ferium upgrade` | Auto-fetches remote/local mod manifest (`server-mods.txt`), registers mods, and upgrades binaries directly to `.minecraft/mods`. |
| **2** | **Upgrade / Sync** | `ferium upgrade` | Downloads and syncs binaries for all currently tracked mods in the profile. |
| **3** | **Add Mods (Batch)** | `ferium add <slug>` | Accepts space- or comma-separated Modrinth slugs or CurseForge IDs, splits via regex (`-split '[\s,]+'`), and adds each sequentially. |
| **4** | **Add & Upgrade** | `ferium add <slug>` + `ferium upgrade` | Performs batch addition and automatically triggers a repository upgrade if at least one mod is successfully added. |
| **5** | **List Tracked Mods** | `ferium list` | Outputs all mods currently registered in the active Ferium profile. |
| **6** | **Remove Tracked Mod** | `ferium remove <slug>` | Untracks a mod from Ferium profile (note: local `.jar` binaries may require manual cleanup). |
| **7** | **Add/Configure Modpack** | `ferium modpack add ...` / `ferium modpack configure ...` | Adds a modpack pointing output to `%APPDATA%\.minecraft`. Includes state recovery fallback to `configure` if already added, followed by `modpack upgrade`. |
| **8** | **Scan Directory** | `ferium scan` | Scans the local `.minecraft/mods` directory for untracked `.jar` files and registers them to Ferium. |
| **9** | **Exit** | `break` | Terminates the interactive shell session cleanly. |

---

## Key Implementation Patterns

1. **Auto-Bootstrap Installer**:
   `Ensure-FeriumInstalled` checks for `ferium.exe` at startup. If missing, it downloads the official Windows release zip from GitHub API/Release assets and extracts it to `$env:LOCALAPPDATA\Ferium\`.
2. **Remote & Local Manifest Fetching**:
   `Get-ModManifest` queries `$script:ManifestUrl` using `Invoke-RestMethod`. If offline or unconfigured, it falls back to reading `script/server-mods.txt`.
3. **Robust Batch Parsing**:
   Uses regular expressions (`[\s,]+`) to split user input strings into individual mod identifiers, ignoring extra whitespace or comma formatting.
4. **State Fallback & Self-Healing**:
   Option 7 attempts `ferium modpack add`. If Ferium returns a non-zero exit code (indicating the pack already exists), it automatically executes `ferium modpack configure --output-dir <path>` to enforce output paths before executing `modpack upgrade`.
5. **Status Tracking**:
   Validates `$LASTEXITCODE` after every CLI call to display color-coded feedback (`[SUCCESS]`, `[ERROR]`, `[WARNING]`).
