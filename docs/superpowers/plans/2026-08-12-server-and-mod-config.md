# Minecraft Server & Mod Configuration Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Create an automated PowerShell configuration script `script/CONFIGURE_SERVER.ps1` that configures `server.properties` and all mod configuration files, and integrate it as Option 4 in `script/MOD_MANAGER.ps1`.

**Architecture:** A standalone PowerShell script `CONFIGURE_SERVER.ps1` reads configuration paths from `config.json` / `server.properties`, programmatically updates key-value pairs and JSON/JSON5 config files inside `D:\Games\minecraft-server\config\`, and is triggered via Option 4 in `MOD_MANAGER.ps1`.

**Tech Stack:** PowerShell 5.1+, JSON / JSON5 / Properties file parsing.

## Global Constraints

- **Server Target Path**: `D:\Games\minecraft-server\`
- **MOTD String**: `\u00A76Hustisya Para Kay Rene \u00A77| \u00A7aSMP`
- **Universal Graves Protection**: `1800` seconds (30 minutes), despawn `-1`.
- **Night Sleep**: Gamerule `playersSleepingPercentage = 0`.
- **Server-Side Horror**: Disables heads (`heads_from_list_enable = false`, `random_heads_enable = false`), starer list `["Herobrine"]`, custom sign texts (`"TABANGI KO"`, `"YAWAAAAAA"`, `"nay iro mamatay unya"`, `"james biot"`, `"ben opaw"`), fake joiners `["Herobrine;ReneBaterbonia"]`.
- **Voice Chat**: UDP port `24454`, distance `48.0`.
- **TAB List**: Format `[${lvl}] ${name} (Deaths: ${deaths} | Playtime: ${playtime} | Ping: ${ping}ms)`.

---

### Task 1: Create Core Server Configurator Script (`script/CONFIGURE_SERVER.ps1`)

**Files:**
- Create: `script/CONFIGURE_SERVER.ps1`
- Test: `scratch/test_configure_server.ps1`

**Interfaces:**
- Consumes: Config paths from `D:\Games\minecraft-server\server.properties` and `D:\Games\minecraft-server\config\`
- Produces: Updated `server.properties` and mod configuration JSON/JSON5 files

- [ ] **Step 1: Write the test script for `CONFIGURE_SERVER.ps1`**

Write `scratch/test_configure_server.ps1`:
```powershell
$scriptPath = "c:\dev\minecraft\script\CONFIGURE_SERVER.ps1"
if (Test-Path -Path $scriptPath) {
    Write-Host "Running CONFIGURE_SERVER.ps1..." -ForegroundColor Cyan
    powershell -ExecutionPolicy Bypass -File $scriptPath
    
    # Verify server.properties edits
    $propContent = Get-Content -Path "D:\Games\minecraft-server\server.properties" -Raw
    if ($propContent -match "motd=\\u00A76Hustisya Para Kay Rene" -and $propContent -match "difficulty=hard") {
        Write-Host "PASS: server.properties configured successfully!" -ForegroundColor Green
    } else {
        Write-Error "FAIL: server.properties MOTD or difficulty check failed"
    }
} else {
    Write-Error "FAIL: script/CONFIGURE_SERVER.ps1 not found"
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `powershell -ExecutionPolicy Bypass -File C:\Users\Red\.gemini\antigravity-ide\brain\6f85dfef-4a34-4780-89d5-cb7dc7d34977\scratch\test_configure_server.ps1`
Expected: FAIL with `script/CONFIGURE_SERVER.ps1 not found`.

- [ ] **Step 3: Write minimal implementation in `script/CONFIGURE_SERVER.ps1`**

Create `script/CONFIGURE_SERVER.ps1`:
```powershell
# Minecraft Server & Mod Configurator Script
Write-Host "`n[*] Starting Minecraft Server & Mod Configuration..." -ForegroundColor Cyan

$serverDir = "D:\Games\minecraft-server"
$propFile = Join-Path -Path $serverDir -ChildPath "server.properties"
$configDir = Join-Path -Path $serverDir -ChildPath "config"

if (-not (Test-Path -Path $propFile)) {
    Write-Host "[ERROR] server.properties not found at $propFile" -ForegroundColor Red
    return
}

# 1. Update server.properties
Write-Host "[*] Configuring server.properties..." -ForegroundColor Cyan
$props = Get-Content -Path $propFile
$newProps = @()
foreach ($line in $props) {
    if ($line.StartsWith("motd=")) {
        $newProps += "motd=\\u00A76Hustisya Para Kay Rene \\u00A77| \\u00A7aSMP"
    } elseif ($line.StartsWith("difficulty=")) {
        $newProps += "difficulty=hard"
    } elseif ($line.StartsWith("online-mode=")) {
        $newProps += "online-mode=false"
    } elseif ($line.StartsWith("view-distance=")) {
        $newProps += "view-distance=10"
    } elseif ($line.StartsWith("simulation-distance=")) {
        $newProps += "simulation-distance=10"
    } else {
        $newProps += $line
    }
}
$newProps | Set-Content -Path $propFile -Encoding UTF8
Write-Host " -> server.properties updated!" -ForegroundColor Green

# 2. Update Universal Graves Config
$gravesDir = Join-Path -Path $configDir -ChildPath "universal-graves"
if (-not (Test-Path -Path $gravesDir)) { New-Item -ItemType Directory -Path $gravesDir -Force | Out-Null }
$gravesConfig = Join-Path -Path $gravesDir -ChildPath "config.json"
$gravesJson = @{
    "protection_time" = 1800
    "grave_despawn_time" = -1
} | ConvertTo-Json -Depth 5
$gravesJson | Set-Content -Path $gravesConfig -Encoding UTF8
Write-Host " -> Universal Graves config updated (30m protection)!" -ForegroundColor Green

# 3. Update Server-Side Horror Config
$horrorConfig = Join-Path -Path $configDir -ChildPath "serversidehorror.json"
if (Test-Path -Path $horrorConfig) {
    try {
        $hObj = Get-Content -Path $horrorConfig -Raw | ConvertFrom-Json
        $hObj.heads_from_list_enable = $false
        $hObj.random_heads_enable = $false
        $hObj.starer_list = @("Herobrine")
        $hObj.fake_steps_chance = 150000
        $hObj.fake_mining_chance = 150000
        $hObj.scary_sound_chance = 250000
        $hObj.random_signs_texts = @("TABANGI KO", "YAWAAAAAA", "nay iro mamatay unya", "james biot", "ben opaw")
        $hObj.random_fake_joiner_list = @("Herobrine;ReneBaterbonia")
        $hObj | ConvertTo-Json -Depth 10 | Set-Content -Path $horrorConfig -Encoding UTF8
        Write-Host " -> Server-Side Horror config updated with custom signs and Herobrine!" -ForegroundColor Green
    } catch {
        Write-Host "[WARNING] Could not parse serversidehorror.json: $_" -ForegroundColor Yellow
    }
}

Write-Host "`n[SUCCESS] Minecraft Server & Mod Configuration complete!" -ForegroundColor Green
```

- [ ] **Step 4: Run test to verify it passes**

Run: `powershell -ExecutionPolicy Bypass -File C:\Users\Red\.gemini\antigravity-ide\brain\6f85dfef-4a34-4780-89d5-cb7dc7d34977\scratch\test_configure_server.ps1`
Expected: PASS with `server.properties configured successfully!`.

- [ ] **Step 5: Commit**

```bash
git add script/CONFIGURE_SERVER.ps1
git commit -m "feat: create script/CONFIGURE_SERVER.ps1 for automated server and mod settings"
```

---

### Task 2: Integrate `CONFIGURE_SERVER.ps1` into `MOD_MANAGER.ps1`

**Files:**
- Modify: `script/MOD_MANAGER.ps1:330-380`
- Test: `scratch/test_syntax.ps1`

**Interfaces:**
- Consumes: `script/CONFIGURE_SERVER.ps1`
- Produces: Main interactive CLI menu option 4 in `script/MOD_MANAGER.ps1`

- [ ] **Step 1: Write test to check menu integration**

Write `scratch/test_menu_option.ps1`:
```powershell
$content = Get-Content -Path "c:\dev\minecraft\script\MOD_MANAGER.ps1" -Raw
if ($content -match "Option 4" -or $content -match "CONFIGURE_SERVER") {
    Write-Host "PASS: Option 4 registered in MOD_MANAGER.ps1" -ForegroundColor Green
} else {
    Write-Error "FAIL: Option 4 not found in MOD_MANAGER.ps1"
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `powershell -ExecutionPolicy Bypass -File C:\Users\Red\.gemini\antigravity-ide\brain\6f85dfef-4a34-4780-89d5-cb7dc7d34977\scratch\test_menu_option.ps1`
Expected: FAIL with `Option 4 not found in MOD_MANAGER.ps1`.

- [ ] **Step 3: Modify `script/MOD_MANAGER.ps1` to add Option 4**

Update `Show-Menu` in `script/MOD_MANAGER.ps1`:
```powershell
    Write-Host "==========================================" -ForegroundColor Cyan
    Write-Host "     MINECRAFT MOD MANAGER (Fabric 26.2)   " -ForegroundColor Yellow
    Write-Host "==========================================" -ForegroundColor Cyan
    Write-Host "  1. 1-Click Server Mod Sync (Install/Update)" -ForegroundColor Green
    Write-Host "  2. Switch Active Profile (Server / Main)" -ForegroundColor Green
    Write-Host "  3. Check Mod Status / List Tracked Mods" -ForegroundColor Green
    Write-Host "  4. Configure Server & World Settings" -ForegroundColor Green
    Write-Host "  5. Exit" -ForegroundColor Red
    Write-Host "==========================================" -ForegroundColor Cyan
```
And handle Option 4 in the choice loop:
```powershell
        "4" {
            $confScript = Join-Path -Path $script:PSScriptRoot -ChildPath "CONFIGURE_SERVER.ps1"
            if (Test-Path -Path $confScript) {
                & $confScript
            } else {
                Write-Host "[ERROR] CONFIGURE_SERVER.ps1 script not found!" -ForegroundColor Red
            }
        }
```

- [ ] **Step 4: Run test to verify it passes**

Run: `powershell -ExecutionPolicy Bypass -File C:\Users\Red\.gemini\antigravity-ide\brain\6f85dfef-4a34-4780-89d5-cb7dc7d34977\scratch\test_menu_option.ps1`
Expected: PASS.
Run: `powershell -ExecutionPolicy Bypass -File C:\Users\Red\.gemini\antigravity-ide\brain\6f85dfef-4a34-4780-89d5-cb7dc7d34977\scratch\test_syntax.ps1`
Expected: `AST PARSE SUCCESS: 0 Syntax Errors`.

- [ ] **Step 5: Commit**

```bash
git add script/MOD_MANAGER.ps1
git commit -m "feat: add Option 4 Configure Server Settings to MOD_MANAGER.ps1"
```
