# Multi-Instance & Git-Ignored Configuration Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Implement multi-instance management (`server` vs `main` profile) with git-ignored local `config.json` storage in `script/MOD_MANAGER.ps1`.

**Architecture:** PowerShell helper functions `Get-ScriptConfig` and `Switch-ActiveProfile` reading and persisting local profile configurations in `$PSScriptRoot/config.json`. Auto-defaults to `%APPDATA%\.minecraft\mods` if `config.json` is missing.

**Tech Stack:** PowerShell 5.1+, `ConvertFrom-Json` / `ConvertTo-Json`, `.gitignore`.

## Global Constraints

- Target script: `script/MOD_MANAGER.ps1`
- Config file: `script/config.json` (git-ignored)
- Default fallback mods directory: `$env:APPDATA\.minecraft\mods`

---

### Task 1: `.gitignore` Protection & `Get-ScriptConfig` Helper

**Files:**
- Modify: [`.gitignore`](file:///c:/dev/minecraft/.gitignore)
- Modify: [`script/MOD_MANAGER.ps1`](file:///c:/dev/minecraft/script/MOD_MANAGER.ps1)

**Interfaces:**
- Consumes: `$PSScriptRoot/config.json`
- Produces: Function `Get-ScriptConfig` resolving `$script:ActiveProfile` and `$script:MinecraftMods`.

- [ ] **Step 1: Update `.gitignore`**

Add `config.json` and `script/config.json` to `.gitignore`.

- [ ] **Step 2: Implement `Get-ScriptConfig` in `MOD_MANAGER.ps1`**

Add `Get-ScriptConfig` function. If `config.json` doesn't exist, create it with default profile `main` (`$env:APPDATA\.minecraft\mods`). Resolve `$script:ActiveProfile` and `$script:MinecraftMods`.

- [ ] **Step 3: Test `Get-ScriptConfig` execution**

Verify AST parsing and execution in PowerShell.

- [ ] **Step 4: Commit Task 1**

```bash
git add .gitignore script/MOD_MANAGER.ps1
git commit -m "feat: add config.json loader and gitignore protection"
```

---

### Task 2: Profile Switcher & Menu Integration

**Files:**
- Modify: [`script/MOD_MANAGER.ps1`](file:///c:/dev/minecraft/script/MOD_MANAGER.ps1)

**Interfaces:**
- Consumes: `$PSScriptRoot/config.json`
- Produces: Function `Switch-ActiveProfile` toggling profile and saving back to `config.json`.

- [ ] **Step 1: Implement `Switch-ActiveProfile` function**

Add `Switch-ActiveProfile` to cycle through profile keys in `config.json`, update `active_profile`, and save JSON back to disk.

- [ ] **Step 2: Update Menu Banner & Option 2**

Update header banner to display `Active Profile: [<name>] -> <path>`. Add option `2. 🔄 Switch Target Instance Profile` and shift subsequent options accordingly.

- [ ] **Step 3: Test profile switching**

Run PowerShell test verifying `Switch-ActiveProfile` updates `config.json`.

- [ ] **Step 4: Commit Task 2**

```bash
git add script/MOD_MANAGER.ps1
git commit -m "feat: add profile switcher and menu integration"
```

---

### Task 3: Verification & Documentation Update

**Files:**
- Modify: [`docs/PROJECT_CONTEXT.md`](file:///c:/dev/minecraft/docs/PROJECT_CONTEXT.md)
- Modify: [`docs/BACKLOG.md`](file:///c:/dev/minecraft/docs/BACKLOG.md)

**Interfaces:**
- Consumes: Complete `MOD_MANAGER.ps1` workflow.
- Produces: Verified executable script and updated documentation.

- [ ] **Step 1: Run verification suite**

Verify AST syntax, profile switching, and 1-Click Sync resolution.

- [ ] **Step 2: Update documentation**

Update `docs/PROJECT_CONTEXT.md` and `docs/BACKLOG.md` detailing multi-profile `config.json` support.

- [ ] **Step 3: Commit Task 3**

```bash
git add docs/PROJECT_CONTEXT.md docs/BACKLOG.md
git commit -m "docs: update project context and backlog for multi-instance config"
```
