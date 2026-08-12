# Project Context: Ferium Minecraft Mod Manager

## Overview
This repository contains management tools for maintaining Minecraft client mods and modpacks using [Ferium](https://github.com/the-cursed-modpack/ferium), a fast CLI manager supporting Modrinth and CurseForge.

The central component is the interactive PowerShell script located at [`script/MOD_MANAGER.ps1`](file:///c:/dev/minecraft/script/MOD_MANAGER.ps1).

---

## Environment & Path Configuration

- **Ferium Directory**: `$env:LOCALAPPDATA\Ferium` (auto-created)
- **Ferium Executable**: `$env:LOCALAPPDATA\Ferium\ferium.exe` (auto-downloaded from GitHub releases if missing)
- **Git-Ignored Local Config**: `script/config.json` (stores multi-instance profiles with custom paths, Minecraft versions, and mod loaders)
- **Target Minecraft Mods**: `$script:MinecraftMods` (dynamically resolved based on `$script:ActiveProfile`)
- **Active Game Version**: `$script:ActiveMcVersion` (e.g. `26.2`, `1.21.1`, `1.20.4`)
- **Active Mod Loader**: `$script:ActiveModLoader` (e.g. `fabric`, `quilt`, `forge`, `neo-forge`)
- **Shared Manifest**: [`script/server-mods.txt`](file:///c:/dev/minecraft/script/server-mods.txt) (contains client-required and shared mods)
- **Server-Only Manifest**: [`script/server-only-mods.txt`](file:///c:/dev/minecraft/script/server-only-mods.txt) (contains server-side-only mods like `tree-harvester`)
- **PowerShell Error Preference**: `$ErrorActionPreference = "Continue"`

---

## Script Architecture & Functionality

The interactive menu loop (`MOD_MANAGER.ps1`) provides 11 operational workflows:

| Option | Operation | Ferium Command / Logic | Description |
| :--- | :--- | :--- | :--- |
| **1** | **1-Click Server Mod Sync** | `Get-ModManifest` + `ferium add` + `ferium upgrade` | Auto-fetches mod manifests (`server-mods.txt` for client; plus `server-only-mods.txt` for server profile), registers mods, and upgrades binaries directly to target `mods` directory. |
| **2** | **Switch Instance Profile** | `Switch-ActiveProfile` | Toggles active instance profile (`server` $\leftrightarrow$ `main`) and updates `config.json`. |
| **3** | **Upgrade / Sync** | `ferium upgrade` | Downloads and syncs binaries for all currently tracked mods in the active profile. |
| **4** | **Add Mods (Batch)** | `ferium add <slug>` | Accepts space- or comma-separated Modrinth slugs or CurseForge IDs, splits via regex (`-split '[\s,]+'`), and adds each sequentially. |
| **5** | **Add & Upgrade** | `ferium add <slug>` + `ferium upgrade` | Performs batch addition and automatically triggers a repository upgrade if at least one mod is successfully added. |
| **6** | **List Tracked Mods** | `ferium list` | Outputs all mods currently registered in the active Ferium profile. |
| **7** | **Remove Tracked Mod** | `ferium remove <slug>` | Untracks a mod from Ferium profile (note: local `.jar` binaries may require manual cleanup). |
| **8** | **Add/Configure Modpack** | `ferium modpack add ...` / `ferium modpack configure ...` | Adds a modpack pointing output to `%APPDATA%\.minecraft`. Includes state recovery fallback to `configure` if already added, followed by `modpack upgrade`. |
| **9** | **Scan Directory** | `ferium scan` | Scans the local `.minecraft/mods` directory for untracked `.jar` files and registers them to Ferium. |
| **10** | **Configure Settings** | `Set-InstanceSettings` | Interactively updates the Minecraft version (`mc_version`) and loader (`mod_loader`) for the active profile and saves to `config.json`. |
| **11** | **Exit** | `break` | Terminates the interactive shell session cleanly. |

---

## Key Implementation Patterns

1. **Dual Manifest Separation**:
   - `server-mods.txt` stores client-required and shared mods (shared with friends).
   - `server-only-mods.txt` stores server-side-only mods (`tree-harvester`).
   - `Sync-ServerMods` loads `server-mods.txt` for player profiles, and both manifests for `server` profile.
2. **Per-Profile Version & Loader Management**:
   `Get-ScriptConfig` loads `{ path, mc_version, mod_loader }` objects from `config.json`. `Set-InstanceSettings` allows configuring version/loader per profile.
3. **Ferium CLI Profile Synchronization**:
   `Ensure-FeriumProfile` syncs `$script:ActiveProfile` with Ferium's internal profiles via `ferium profile list`, `ferium profile create`, `ferium profile switch`, and `ferium profile configure`.
4. **Auto-Bootstrap Installer**:
   `Ensure-FeriumInstalled` checks for `ferium.exe` at startup. If missing, it downloads the official Windows release zip from GitHub API/Release assets and extracts it to `$env:LOCALAPPDATA\Ferium\`.
5. **Robust Batch Parsing**:
   Uses regular expressions (`[\s,]+`) to split user input strings into individual mod identifiers, ignoring extra whitespace or comma formatting.
