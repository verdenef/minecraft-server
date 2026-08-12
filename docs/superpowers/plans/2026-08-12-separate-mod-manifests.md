# Separate Client & Server-Only Mod Manifests Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Separate Minecraft mods into two manifest files (`server-mods.txt` for client/shared mods and `server-only-mods.txt` for server-only mods) and update `MOD_MANAGER.ps1` to sync both on server profiles while syncing only client mods on player profiles.

**Architecture:** Refactor `Get-ModManifest` to accept a target filename parameter. Update `Sync-ServerMods` to conditionally load both `server-mods.txt` and `server-only-mods.txt` when `$script:ActiveProfile -eq "server"`, while syncing only `server-mods.txt` for client profiles.

**Tech Stack:** PowerShell 5.1+, Ferium CLI, JSON, Git.

## Global Constraints

- File Encoding: UTF-8 for scripts and manifests.
- Backward Compatibility: `Get-ModManifest` defaults to `server-mods.txt` if `-FileName` is omitted.
- Execution Policy: Non-blocking interactive PowerShell CLI execution.

---

### Task 1: Separate Manifest Files Creation

**Files:**
- Create: `script/server-only-mods.txt`
- Modify: `script/server-mods.txt`
- Test: `scratch/test_manifest_files.ps1`

**Interfaces:**
- Consumes: Manifest text lines (mod slugs)
- Produces: `script/server-only-mods.txt` (server-only slugs) and `script/server-mods.txt` (client/shared slugs)

- [ ] **Step 1: Create `script/server-only-mods.txt`**

```text
# Minecraft Server-Only Mod Manifest
# Add Modrinth slugs or CurseForge IDs below (one per line)
tree-harvester
```

- [ ] **Step 2: Update `script/server-mods.txt` to remove server-only mods**

Remove `tree-harvester` from `script/server-mods.txt`, keeping the 31 client/shared mods.

- [ ] **Step 3: Write test script to verify both manifest files exist**

Create `scratch/test_manifest_files.ps1`:
```powershell
$clientManifest = "script/server-mods.txt"
$serverManifest = "script/server-only-mods.txt"

if ((Test-Path $clientManifest) -and (Test-Path $serverManifest)) {
    Write-Host "Both manifest files verified on disk!" -ForegroundColor Green
} else {
    Write-Error "Manifest files missing!"
}
```

- [ ] **Step 4: Run test to verify**

Run: `powershell -ExecutionPolicy Bypass -File scratch/test_manifest_files.ps1`
Expected: `Both manifest files verified on disk!`

- [ ] **Step 5: Commit Task 1**

```bash
git add script/server-mods.txt script/server-only-mods.txt
git commit -m "feat: separate server-only-mods.txt from shared server-mods.txt manifest"
```

---

### Task 2: Update `Get-ModManifest` & `Sync-ServerMods` Functions

**Files:**
- Modify: `script/MOD_MANAGER.ps1:180-265`
- Test: `scratch/test_manifest_sync.ps1`

**Interfaces:**
- Consumes: `$script:ActiveProfile` and manifest filenames
- Produces: `Get-ModManifest -FileName <string>` and conditional dual-manifest `Sync-ServerMods`

- [ ] **Step 1: Write failing test script for new `Get-ModManifest` signature**

Create `scratch/test_manifest_sync.ps1`:
```powershell
$tokens = $null
$errors = $null
$ast = [System.Management.Automation.Language.Parser]::ParseFile("c:\dev\minecraft\script\MOD_MANAGER.ps1", [ref]$tokens, [ref]$errors)

if ($errors.Count -ne 0) {
    Write-Error "AST syntax error"
    exit 1
}

$funcs = $ast.FindAll({ $args[0] -is [System.Management.Automation.Language.FunctionDefinitionAst] }, $true)
foreach ($f in $funcs) {
    Invoke-Expression $f.Extent.Text
}

$clientMods = Get-ModManifest -FileName "server-mods.txt"
$serverOnlyMods = Get-ModManifest -FileName "server-only-mods.txt"

if ($clientMods.Count -gt 0 -and $serverOnlyMods -contains "tree-harvester") {
    Write-Host "Dual manifest parsing test PASSED!" -ForegroundColor Green
} else {
    Write-Error "Dual manifest parsing test FAILED"
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `powershell -ExecutionPolicy Bypass -File scratch/test_manifest_sync.ps1`
Expected: Fails or ignores `-FileName` parameter.

- [ ] **Step 3: Update `Get-ModManifest` in `script/MOD_MANAGER.ps1`**

```powershell
function Get-ModManifest {
    param (
        [string]$FileName = "server-mods.txt"
    )
    
    $content = ""
    if (-not [string]::IsNullOrWhiteSpace($script:ManifestUrl) -and $FileName -eq "server-mods.txt") {
        try {
            Write-Host "[*] Fetching remote server mod manifest from URL..." -ForegroundColor Cyan
            [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
            $content = Invoke-RestMethod -Uri $script:ManifestUrl -UseBasicParsing
        } catch {
            Write-Host "[WARNING] Failed to fetch remote manifest from $script:ManifestUrl : $_" -ForegroundColor Yellow
        }
    }
    
    if ([string]::IsNullOrWhiteSpace($content)) {
        $candidates = @()
        if (-not [string]::IsNullOrWhiteSpace($PSScriptRoot)) {
            $candidates += Join-Path -Path $PSScriptRoot -ChildPath $FileName
            $candidates += Join-Path -Path $PSScriptRoot -ChildPath "..\script\$FileName"
        }
        $candidates += "script\$FileName"
        $candidates += $FileName
        
        $localManifest = $null
        foreach ($path in $candidates) {
            if (Test-Path -Path $path) {
                $localManifest = $path
                break
            }
        }
        
        if ($localManifest) {
            Write-Host "[*] Reading local manifest from $localManifest..." -ForegroundColor Cyan
            $content = Get-Content -Path $localManifest -Raw
        } else {
            if ($FileName -ne "server-only-mods.txt") {
                Write-Host "[ERROR] No remote URL configured and local $FileName not found!" -ForegroundColor Red
            }
            return @()
        }
    }
    
    $mods = $content -split '[\r\n]+' | Where-Object { 
        $line = $_.Trim()
        $line -and -not $line.StartsWith("#")
    }
    return $mods
}
```

- [ ] **Step 4: Update `Sync-ServerMods` in `script/MOD_MANAGER.ps1`**

```powershell
function Sync-ServerMods {
    Write-Host "`n[*] Starting Server Mod Synchronization..." -ForegroundColor Cyan
    Write-Host "[*] Target Profile: [$script:ActiveProfile]" -ForegroundColor Cyan
    Write-Host "[*] Target Mods Directory: $script:MinecraftMods" -ForegroundColor Gray
    
    if (-not (Test-Path -Path $script:MinecraftMods)) {
        New-Item -ItemType Directory -Path $script:MinecraftMods -Force | Out-Null
    }
    
    $mods = @()
    $mods += Get-ModManifest -FileName "server-mods.txt"
    
    if ($script:ActiveProfile -eq "server") {
        Write-Host "[*] Server profile detected: Including server-only mods..." -ForegroundColor Yellow
        $mods += Get-ModManifest -FileName "server-only-mods.txt"
    }
    
    if ($mods.Count -eq 0) {
        Write-Host "[WARNING] No mods found in manifest to sync." -ForegroundColor Yellow
        return
    }
    
    Write-Host "[*] Registering $($mods.Count) mods into Ferium profile..." -ForegroundColor Cyan
    foreach ($mod in $mods) {
        Write-Host " -> Adding '$mod'..." -ForegroundColor Gray
        & $script:FeriumExe add $mod | Out-Null
    }
    
    Write-Host "`n[*] Pulling mod binaries to $script:MinecraftMods..." -ForegroundColor Cyan
    & $script:FeriumExe upgrade
    
    if ($LASTEXITCODE -eq 0) {
        Write-Host "`n[SUCCESS] Mods successfully synchronized to $script:MinecraftMods!" -ForegroundColor Green
    } else {
        Write-Host "`n[ERROR] Mod upgrade completed with warnings or non-zero exit code: $LASTEXITCODE" -ForegroundColor Yellow
    }
}
```

- [ ] **Step 5: Run test script to verify**

Run: `powershell -ExecutionPolicy Bypass -File scratch/test_manifest_sync.ps1`
Expected: `Dual manifest parsing test PASSED!`

- [ ] **Step 6: Commit Task 2**

```bash
git add script/MOD_MANAGER.ps1
git commit -m "feat: refactor Get-ModManifest and Sync-ServerMods for dual manifest support"
```

---

### Task 3: Verification & Documentation Update

**Files:**
- Modify: `docs/PROJECT_CONTEXT.md`
- Modify: `docs/BACKLOG.md`
- Test: `scratch/test_full_verification.ps1`

**Interfaces:**
- Consumes: Complete project state
- Produces: Updated docs and passing end-to-end verification

- [ ] **Step 1: Write end-to-end verification script**

Create `scratch/test_full_verification.ps1`:
```powershell
$tokens = $null
$errors = $null
$ast = [System.Management.Automation.Language.Parser]::ParseFile("c:\dev\minecraft\script\MOD_MANAGER.ps1", [ref]$tokens, [ref]$errors)

if ($errors.Count -eq 0) {
    Write-Host "AST VERIFICATION SUCCESS: 0 Syntax Errors" -ForegroundColor Green
} else {
    Write-Error "AST VERIFICATION FAILED"
}
```

- [ ] **Step 2: Run verification script**

Run: `powershell -ExecutionPolicy Bypass -File scratch/test_full_verification.ps1`
Expected: `AST VERIFICATION SUCCESS: 0 Syntax Errors`

- [ ] **Step 3: Update `docs/PROJECT_CONTEXT.md` and `docs/BACKLOG.md`**

Add documentation detailing `server-mods.txt` vs `server-only-mods.txt`.

- [ ] **Step 4: Commit Task 3**

```bash
git add docs/PROJECT_CONTEXT.md docs/BACKLOG.md
git commit -m "docs: update project context and backlog for separate client and server-only manifests"
```
