# Per-Profile Minecraft Version & Loader Configuration Design Specification

**Date:** 2026-08-12  
**Target Script:** [`script/MOD_MANAGER.ps1`](file:///c:/dev/minecraft/script/MOD_MANAGER.ps1)  
**Status:** Approved  

---

## 1. Problem & Goal

Currently, `config.json` stores instance profile paths as plain strings. Minecraft game version (`26.2`) and mod loader (`fabric`) are hardcoded in the script initialization. Different instances (e.g. `server` vs `main`) may run different Minecraft versions (e.g., `26.2`, `1.21.1`, `1.20.4`) or loaders (`fabric`, `quilt`, `forge`, `neo-forge`).

Goal: Store `mc_version` and `mod_loader` per profile in `config.json`, add menu option `10. ⚙️ Configure Active Instance Settings`, and auto-configure Ferium CLI upon profile switches or setting changes.

---

## 2. Configuration Schema (`script/config.json`)

```json
{
  "active_profile": "server",
  "profiles": {
    "server": {
      "path": "C:\\Users\\Red\\AppData\\Roaming\\.minecraft\\instances\\64290aca06184fb6b59be8d2ef380ff5\\mods",
      "mc_version": "26.2",
      "mod_loader": "fabric"
    },
    "main": {
      "path": "%APPDATA%\\.minecraft\\mods",
      "mc_version": "26.2",
      "mod_loader": "fabric"
    }
  }
}
```

---

## 3. Function & Workflow Updates

1. **`Get-ScriptConfig`**:
   - Parses `config.json`.
   - Backward Compatibility: If a profile value is a plain string path (legacy schema), automatically converts it to an object with defaults (`mc_version = "26.2"`, `mod_loader = "fabric"`).
   - Sets `$script:ActiveMcVersion` and `$script:ActiveModLoader`.

2. **`Ensure-FeriumProfile`**:
   - Invokes `ferium profile configure --game-version $script:ActiveMcVersion --mod-loader $script:ActiveModLoader --output-dir "$script:MinecraftMods"`.
   - If profile does not exist in Ferium, creates it using `--game-version $script:ActiveMcVersion --mod-loader $script:ActiveModLoader`.

3. **`Set-InstanceSettings`**:
   - Interactive prompt allowing the user to update `mc_version` and `mod_loader` for the current `$script:ActiveProfile`.
   - Saves updated object back to `config.json` and calls `Get-ScriptConfig`.

4. **UI Banner & Menu Option**:
   - Header banner displays: `Target: [$script:ActiveProfile] (MC: $script:ActiveMcVersion | $script:ActiveModLoader) -> $script:MinecraftMods`
   - Option `10`: `⚙️ Configure Active Instance Settings [MC Version / Loader]`
   - Option `11`: `Exit`
