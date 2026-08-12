# Ferium CLI Profile Synchronization Design Specification

**Date:** 2026-08-12  
**Target Script:** [`script/MOD_MANAGER.ps1`](file:///c:/dev/minecraft/script/MOD_MANAGER.ps1)  
**Status:** Approved  

---

## 1. Problem & Goal

Currently, switching `$script:ActiveProfile` in `MOD_MANAGER.ps1` only updates internal script variables (`$script:MinecraftMods`), leaving Ferium CLI's internal profile unchanged. As a result, operations like `ferium list` (Option 6) or `ferium remove` (Option 7) target Ferium's previous active profile (`sklauncher`).

Goal: Implement automatic Ferium CLI profile creation, switching, and directory configuration (`Ensure-FeriumProfile`) whenever the active profile changes.

---

## 2. Architecture & Data Flow

```
[Get-ScriptConfig / Switch-ActiveProfile]
               │
               ▼
     [Ensure-FeriumProfile]
               │
   ┌───────────┴───────────┐
   ▼                       ▼
(Profile missing in    (Profile exists in
   Ferium CLI)            Ferium CLI)
   │                       │
   ▼                       ▼
[ferium profile create] [ferium profile switch]
   │                       │
   └───────────┬───────────┘
               ▼
[ferium profile configure --output-dir <mods_path>]
```

---

## 3. Function Interfaces

### `Ensure-FeriumProfile`
- Runs `& $script:FeriumExe profile list` to check registered Ferium profiles.
- Parses profile names using regex/string processing.
- If `$script:ActiveProfile` is missing from Ferium:
  Executes `& $script:FeriumExe profile create --name $script:ActiveProfile --output-dir "$script:MinecraftMods" --mod-loader fabric`
- Executes `& $script:FeriumExe profile switch $script:ActiveProfile` to make it active in Ferium.
- Executes `& $script:FeriumExe profile configure --output-dir "$script:MinecraftMods"` to ensure Ferium's output path matches `$script:MinecraftMods`.

---

## 4. Menu & Workflow Integration

- Call `Ensure-FeriumProfile` inside `Get-ScriptConfig` and `Switch-ActiveProfile`.
- Every menu option (1 through 9) will now execute against the synchronized Ferium profile.
