# Project Backlog & Roadmap

This document tracks completed features, active tasks, and proposed improvements for the Ferium Minecraft Mod Manager (`script/MOD_MANAGER.ps1`).

---

## 📋 To-Do / Planned Improvements

### High Priority
- [ ] **Dynamic Ferium Binary Resolution**: Replace hardcoded `D:\Downloads\appl\ferium.exe` with a fallback mechanism that checks `$env:PATH` or reads from a local `.env`/`config.json` file.
- [ ] **Mod Removal Binary Cleanup**: Enhance Option 5 (`Remove a Tracked Mod`) to optionally search `%APPDATA%\.minecraft\mods` for the corresponding `.jar` file and prompt the user to remove it.

### Medium Priority
- [ ] **Profile Switcher**: Add an interactive menu option to switch Ferium profiles (e.g., between different Minecraft versions or loaders like Fabric, Forge, NeoForge).
- [ ] **Input Sanitization & Validation**: Sanitize user inputs for mod slugs/IDs to catch invalid characters before executing `ferium add`.
- [ ] **Logging & Export**: Option to log CLI command outputs to a `logs/` directory for debugging upgrade or scan failures.

### Low Priority / Quality of Life
- [ ] **Auto-Detect Minecraft Installation Path**: Allow overriding default `%APPDATA%\.minecraft` path via command-line parameter or environment variable.
- [ ] **Batch Removal Support**: Extend Option 5 to support removing multiple mod slugs in a single batch command similar to Option 2.

---

## ✅ Completed Tasks

- [x] **Initial Script Framework**: Created interactive PowerShell CLI menu wrapper (`script/MOD_MANAGER.ps1`).
- [x] **Batch Add Parsing**: Implemented regex-based split (`-split '[\s,]+'`) for adding multiple mods in one prompt (Options 2 & 3).
- [x] **Modpack Self-Healing Fallback**: Implemented automatic fallback from `modpack add` to `modpack configure` if a modpack is already registered (Option 6).
- [x] **Folder Scanner**: Integrated `ferium scan` for detecting untracked `.jar` files in the mods folder (Option 7).
- [x] **Project Documentation**: Created `docs/PROJECT_CONTEXT.md` detailing script architecture, command mapping, and technical specs.
