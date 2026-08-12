# Ferium CLI Profile Synchronization Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Synchronize script profile switching with Ferium CLI's internal profile manager (`Ensure-FeriumProfile`) so all menu options (`list`, `add`, `remove`, `upgrade`, `scan`) operate on the correct profile.

**Architecture:** A PowerShell function `Ensure-FeriumProfile` that invokes Ferium CLI profile commands (`profile list`, `profile create`, `profile switch`, `profile configure`) whenever `$script:ActiveProfile` changes.

**Tech Stack:** PowerShell 5.1+, Ferium CLI profile commands.

## Global Constraints

- Target script: `script/MOD_MANAGER.ps1`
- Ferium binary: `$script:FeriumExe` (`$env:LOCALAPPDATA\Ferium\ferium.exe`)
- Profile switcher function: `Ensure-FeriumProfile`

---

### Task 1: `Ensure-FeriumProfile` Implementation & Integration

**Files:**
- Modify: [`script/MOD_MANAGER.ps1`](file:///c:/dev/minecraft/script/MOD_MANAGER.ps1)

**Interfaces:**
- Consumes: `$script:ActiveProfile`, `$script:MinecraftMods`
- Produces: Function `Ensure-FeriumProfile` syncing Ferium CLI profiles with `$script:ActiveProfile`.

- [ ] **Step 1: Implement `Ensure-FeriumProfile` function**

Add `Ensure-FeriumProfile` to list Ferium profiles, create `$script:ActiveProfile` if missing in Ferium, run `ferium profile switch`, and enforce `--output-dir`.

- [ ] **Step 2: Integrate `Ensure-FeriumProfile` into script flow**

Invoke `Ensure-FeriumProfile` at end of `Get-ScriptConfig` and `Switch-ActiveProfile`.

- [ ] **Step 3: Test profile synchronization**

Run PowerShell verification script confirming `ferium profile list` matches `$script:ActiveProfile`.

- [ ] **Step 4: Commit Task 1**

```bash
git add script/MOD_MANAGER.ps1
git commit -m "feat: synchronize script profile switcher with Ferium CLI profiles"
```

---

### Task 2: End-to-End Verification & Documentation Update

**Files:**
- Modify: [`docs/PROJECT_CONTEXT.md`](file:///c:/dev/minecraft/docs/PROJECT_CONTEXT.md)
- Modify: [`docs/BACKLOG.md`](file:///c:/dev/minecraft/docs/BACKLOG.md)

**Interfaces:**
- Consumes: Verified `script/MOD_MANAGER.ps1` with profile sync.
- Produces: Updated documentation.

- [ ] **Step 1: Verify option 6 (`ferium list`) under `server` profile**

Run verification test confirming `ferium list` under `server` profile outputs `server` mods rather than `main` mods.

- [ ] **Step 2: Update documentation**

Update `docs/PROJECT_CONTEXT.md` and `docs/BACKLOG.md` detailing Ferium CLI profile synchronization.

- [ ] **Step 3: Commit Task 2**

```bash
git add docs/PROJECT_CONTEXT.md docs/BACKLOG.md
git commit -m "docs: update project context for ferium cli profile sync"
```
