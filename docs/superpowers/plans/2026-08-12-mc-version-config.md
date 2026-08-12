# Per-Profile Minecraft Version & Loader Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Allow configuring per-profile Minecraft version (`mc_version`) and mod loader (`mod_loader`) in `script/config.json` and sync them automatically with Ferium CLI.

**Architecture:** Update `config.json` schema to store profile objects with `path`, `mc_version`, and `mod_loader`. Implement `Set-InstanceSettings` interactive menu option and update `Ensure-FeriumProfile` to pass dynamic game version and loader flags to Ferium CLI.

**Tech Stack:** PowerShell 5.1+, `ConvertFrom-Json` / `ConvertTo-Json`, Ferium CLI.

## Global Constraints

- Target script: `script/MOD_MANAGER.ps1`
- Config file: `script/config.json`
- Default version: `26.2`, default loader: `fabric`

---

### Task 1: `config.json` Schema Upgrade & `Set-InstanceSettings` Function

**Files:**
- Modify: [`script/MOD_MANAGER.ps1`](file:///c:/dev/minecraft/script/MOD_MANAGER.ps1)

**Interfaces:**
- Consumes: `script/config.json`
- Produces: `$script:ActiveMcVersion`, `$script:ActiveModLoader`, Function `Set-InstanceSettings`.

- [ ] **Step 1: Upgrade `Get-ScriptConfig` for object schema**

Update `Get-ScriptConfig` to handle profile objects (`{ path, mc_version, mod_loader }`), convert legacy string paths automatically, and export `$script:ActiveMcVersion` and `$script:ActiveModLoader`.

- [ ] **Step 2: Implement `Set-InstanceSettings` function**

Add `Set-InstanceSettings` function to prompt for `mc_version` and `mod_loader`, update `$script:ConfigObj`, save JSON, and reload config.

- [ ] **Step 3: Test schema upgrade**

Run PowerShell script verifying `Get-ScriptConfig` parses both legacy string paths and new profile objects.

- [ ] **Step 4: Commit Task 1**

```bash
git add script/MOD_MANAGER.ps1
git commit -m "feat: add per-profile mc_version and mod_loader config support"
```

---

### Task 2: Ferium Profile Auto-Sync & Menu UI Update

**Files:**
- Modify: [`script/MOD_MANAGER.ps1`](file:///c:/dev/minecraft/script/MOD_MANAGER.ps1)

**Interfaces:**
- Consumes: `$script:ActiveMcVersion`, `$script:ActiveModLoader`
- Produces: Function `Ensure-FeriumProfile` passing dynamic version/loader to Ferium CLI, updated main menu banner and options 10 & 11.

- [ ] **Step 1: Update `Ensure-FeriumProfile` function**

Update `Ensure-FeriumProfile` to pass `--game-version $script:ActiveMcVersion` and `--mod-loader $script:ActiveModLoader` during profile creation and configuration.

- [ ] **Step 2: Update Main Menu UI & Option 10**

Update header banner to display `Target: [$script:ActiveProfile] (MC: $script:ActiveMcVersion | $script:ActiveModLoader) -> $script:MinecraftMods`. Add Option `10. ⚙️ Configure Active Instance Settings` and shift Exit to Option `11`.

- [ ] **Step 3: Test menu and Ferium CLI sync**

Run PowerShell test verifying `Ensure-FeriumProfile` updates Ferium CLI with the selected game version and loader.

- [ ] **Step 4: Commit Task 2**

```bash
git add script/MOD_MANAGER.ps1
git commit -m "feat: sync per-profile game version and loader with Ferium CLI"
```

---

### Task 3: Verification & Documentation Update

**Files:**
- Modify: [`docs/PROJECT_CONTEXT.md`](file:///c:/dev/minecraft/docs/PROJECT_CONTEXT.md)
- Modify: [`docs/BACKLOG.md`](file:///c:/dev/minecraft/docs/BACKLOG.md)

**Interfaces:**
- Consumes: Complete `MOD_MANAGER.ps1` workflow.
- Produces: Verified script and updated documentation.

- [ ] **Step 1: Run verification suite**

Verify AST syntax, profile settings configuration, and Ferium CLI profile output.

- [ ] **Step 2: Update documentation**

Update `docs/PROJECT_CONTEXT.md` and `docs/BACKLOG.md` detailing per-profile Minecraft version and mod loader management.

- [ ] **Step 3: Commit Task 3**

```bash
git add docs/PROJECT_CONTEXT.md docs/BACKLOG.md
git commit -m "docs: update project context and backlog for per-profile mc version management"
```
