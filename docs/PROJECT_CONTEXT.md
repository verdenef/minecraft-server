# Project Context: Ferium Minecraft Mod Manager

## Overview
This repository contains management tools for maintaining Minecraft client mods and modpacks using [Ferium](https://github.com/the-cursed-modpack/ferium), a fast CLI manager supporting Modrinth and CurseForge.

The central component is the interactive PowerShell script located at [`script/MOD_MANAGER.ps1`](file:///c:/dev/minecraft/script/MOD_MANAGER.ps1).

---

## Environment & Path Configuration

- **Ferium Directory**: `D:\Downloads\appl`
- **Ferium Executable**: `D:\Downloads\appl\ferium.exe`
- **Target Minecraft Root**: `$env:APPDATA\.minecraft` (`%APPDATA%\.minecraft`)
- **Target Loader / Version**: Fabric (Profile reference: Fabric 26.2)
- **PowerShell Error Preference**: `$ErrorActionPreference = "Continue"` (prevents menu loop crashes on CLI warnings/non-zero exit codes)

---

## Script Architecture & Functionality

The interactive menu loop (`MOD_MANAGER.ps1`) provides 8 operational workflows:

| Option | Operation | Ferium Command / Logic | Description |
| :--- | :--- | :--- | :--- |
| **1** | **Upgrade / Sync** | `ferium upgrade` | Downloads and syncs binaries for all currently tracked mods in the profile. |
| **2** | **Add Mods (Batch)** | `ferium add <slug>` | Accepts space- or comma-separated Modrinth slugs or CurseForge IDs, splits via regex (`-split '[\s,]+'`), and adds each sequentially. |
| **3** | **Add & Upgrade** | `ferium add <slug>` + `ferium upgrade` | Performs batch addition and automatically triggers a repository upgrade if at least one mod is successfully added. |
| **4** | **List Tracked Mods** | `ferium list` | Outputs all mods currently registered in the active Ferium profile. |
| **5** | **Remove Tracked Mod** | `ferium remove <slug>` | Untracks a mod from Ferium profile (note: local `.jar` binaries may require manual cleanup). |
| **6** | **Add/Configure Modpack** | `ferium modpack add ...` / `ferium modpack configure ...` | Adds a modpack pointing output to `%APPDATA%\.minecraft`. Includes state recovery fallback to `configure` if already added, followed by `modpack upgrade`. |
| **7** | **Scan Directory** | `ferium scan` | Scans the local `.minecraft/mods` directory for untracked `.jar` files and registers them to Ferium. |
| **8** | **Exit** | `break` | Terminates the interactive shell session cleanly. |

---

## Key Implementation Patterns

1. **Robust Batch Parsing**:
   Uses regular expressions (`[\s,]+`) to split user input strings into individual mod identifiers, ignoring extra whitespace or comma formatting.
2. **State Fallback & Self-Healing**:
   Option 6 attempts `ferium modpack add`. If Ferium returns a non-zero exit code (indicating the pack already exists), it automatically executes `ferium modpack configure --output-dir <path>` to enforce output paths before executing `modpack upgrade`.
3. **Status Tracking**:
   Validates `$LASTEXITCODE` after every CLI call to display color-coded feedback (`[SUCCESS]`, `[ERROR]`, `[WARNING]`).

---

## Maintenance Notes & Gotchas

- **Path Dependency**: The script expects `ferium.exe` at `D:\Downloads\appl\ferium.exe`. If moved to a new system or environment, update `$FeriumDir` at [Line 10](file:///c:/dev/minecraft/script/MOD_MANAGER.ps1#L10) or switch to `$env:PATH` resolution.
- **Untracking vs File Deletion**: Untracking a mod via Option 5 removes it from Ferium metadata, but Ferium may leave the compiled `.jar` file inside `.minecraft/mods`.
