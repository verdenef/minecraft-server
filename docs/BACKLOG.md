# Project Backlog & Roadmap

This document tracks completed features, active tasks, and proposed improvements for the Ferium Minecraft Mod Manager (`script/MOD_MANAGER.ps1`).

---

## 📋 To-Do / Planned Improvements

### High Priority
- [ ] **Mod Removal Binary Cleanup**: Enhance Option 7 (`Remove a Tracked Mod`) to optionally search active mods folder for the corresponding `.jar` file and prompt the user to remove it.

### Medium Priority
- [ ] **Input Sanitization & Validation**: Sanitize user inputs for mod slugs/IDs to catch invalid characters before executing `ferium add`.
- [ ] **Logging & Export**: Option to log CLI command outputs to a `logs/` directory for debugging upgrade or scan failures.

### Low Priority / Quality of Life
- [ ] **Batch Removal Support**: Extend Option 7 to support removing multiple mod slugs in a single batch command.

---

## ✅ Completed Tasks

- [x] **Ferium CLI Profile Synchronization**: Implemented `Ensure-FeriumProfile` to automatically sync script profile switching (`server` vs `main`) with Ferium CLI's internal profiles via `ferium profile list`, `profile create`, `profile switch`, and `profile configure --output-dir <path>`.
- [x] **Multi-Instance Config & Profile Switcher**: Added `Get-ScriptConfig` and `Switch-ActiveProfile` (Option 2) with git-ignored `config.json` support. Allows seamlessly toggling between server instances (`.../instances/64290aca.../mods`) and main singleplayer instances (`.minecraft/mods`).
- [x] **1-Click Remote/Local Manifest Sync**: Implemented Option 1 `Sync-ServerMods` to auto-fetch server mod list from remote Gist/URL or local `server-mods.txt` and upgrade directly to target mods directory.
- [x] **Ferium Auto-Bootstrapper**: Dynamic binary resolution in `$env:LOCALAPPDATA\Ferium\ferium.exe` with automatic GitHub release zip downloading if missing.
- [x] **Initial Script Framework**: Created interactive PowerShell CLI menu wrapper (`script/MOD_MANAGER.ps1`).
- [x] **Batch Add Parsing**: Implemented regex-based split (`-split '[\s,]+'`) for adding multiple mods in one prompt.
- [x] **Modpack Self-Healing Fallback**: Implemented automatic fallback from `modpack add` to `modpack configure` if a modpack is already registered.
- [x] **Folder Scanner**: Integrated `ferium scan` for detecting untracked `.jar` files in the mods folder.
- [x] **Project Documentation**: Created `docs/PROJECT_CONTEXT.md` detailing script architecture, command mapping, and technical specs.
