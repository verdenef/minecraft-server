# Minecraft Server Guide & Announcement System Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Implement automated configuration for `welcome-message` and `styled-chat` inside `script/CONFIGURE_SERVER.ps1` to display an in-game welcome guide and announcement system.

**Architecture:** PowerShell script `CONFIGURE_SERVER.ps1` programmatically generates JSON configs for `welcome-message` and `styled-chat` inside `D:\Games\minecraft-server\config\`.

**Tech Stack:** PowerShell 5.1+, JSON parsing.

## Global Constraints

- **Server Target Path**: `D:\Games\minecraft-server\config\`
- **Welcome Message Header**: `§6Hustisya Para Kay Rene §7| §aSMP`
- **Topics Included**: `/skin`, `/nick`, Graves, Tree Harvester, 1-Player Sleep, JourneyMap controls, Shulker inventory open, Fullbright `G`, Zoom `C`, Freecam `F6`.

---

### Task 1: Add Guide & Announcement Configuration to `script/CONFIGURE_SERVER.ps1`

**Files:**
- Modify: `script/CONFIGURE_SERVER.ps1:260-280`
- Test: `scratch/test_configure_server.ps1`

**Interfaces:**
- Consumes: `D:\Games\minecraft-server\config\`
- Produces: `config/welcome-message.json` and `config/styled-chat.json`

- [ ] **Step 1: Write test script for guide configuration**

Write `scratch/test_guide_config.ps1`:
```powershell
$scriptPath = "c:\dev\minecraft\script\CONFIGURE_SERVER.ps1"
powershell -ExecutionPolicy Bypass -File $scriptPath

$wmFile = "D:\Games\minecraft-server\config\welcome-message.json"
if (Test-Path -Path $wmFile) {
    $content = Get-Content -Path $wmFile -Raw
    if ($content -match "Hustisya Para Kay Rene" -and $content -match "skin set") {
        Write-Host "PASS: welcome-message.json generated successfully!" -ForegroundColor Green
    } else {
        Write-Error "FAIL: welcome-message.json content check failed"
    }
} else {
    Write-Error "FAIL: welcome-message.json not found"
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `powershell -ExecutionPolicy Bypass -File C:\Users\Red\.gemini\antigravity-ide\brain\6f85dfef-4a34-4780-89d5-cb7dc7d34977\scratch\test_guide_config.ps1`
Expected: FAIL with `welcome-message.json not found`.

- [ ] **Step 3: Update `script/CONFIGURE_SERVER.ps1` to configure `welcome-message.json`**

Add Section 9 to `script/CONFIGURE_SERVER.ps1`:
```powershell
# ------------------------------------------------------------------------------
# 9. Welcome Guide & Announcements (config/welcome-message.json)
# ------------------------------------------------------------------------------
$wmFile = Join-Path -Path $configDir -ChildPath "welcome-message.json"
$wmObj = [ordered]@{
    "enabled"        = $true
    "welcomeMessage" = @(
        "<gold><bold>════════════════════════════════════════</bold></gold>",
        "<gold><bold>  Welcome to Hustisya Para Kay Rene SMP!</bold></gold>",
        "<gold><bold>════════════════════════════════════════</bold></gold>",
        "<yellow>• Custom Skins:</yellow> <gray>/skin set <SkinName></gray>",
        "<yellow>• Nicknames & Colors:</yellow> <gray>/nick set &aName</gray> or <gray><gradient:#ff4500:#ffa500>Name</gradient></gray>",
        "<yellow>• Graves:</yellow> <gray>30-min item protection on death (1-tap retrieval)</gray>",
        "<yellow>• Tree Harvester:</yellow> <gray>Break bottom log to chop & decay leaves</gray>",
        "<yellow>• 1-Player Sleep:</yellow> <gray>1 player sleeping skips the night</gray>",
        "<yellow>• JourneyMap:</yellow> <gray>[J] Full Map | [B] Waypoints | [Ctrl+B] Quick Pin</gray>",
        "<yellow>• Shulkers:</yellow> <gray>Right-click shulker in inventory to open | Hold Shift to preview</gray>",
        "<yellow>• Keybinds:</yellow> <gray>[G] Fullbright | [C] Zoom | [F6] Freecam | [V] Voice Chat</gray>",
        "<gold><bold>════════════════════════════════════════</bold></gold>"
    )
}
($wmObj | ConvertTo-Json -Depth 5).Replace('\u003c', '<').Replace('\u003e', '>') | Set-Content -Path $wmFile -Encoding UTF8
Write-Host " -> Welcome Guide & Announcements config updated!" -ForegroundColor Green
```

- [ ] **Step 4: Run test to verify it passes**

Run: `powershell -ExecutionPolicy Bypass -File C:\Users\Red\.gemini\antigravity-ide\brain\6f85dfef-4a34-4780-89d5-cb7dc7d34977\scratch\test_guide_config.ps1`
Expected: PASS with `welcome-message.json generated successfully!`.

- [ ] **Step 5: Commit**

```bash
git add script/CONFIGURE_SERVER.ps1
git commit -m "feat: add in-game Welcome Guide & Announcements to CONFIGURE_SERVER.ps1"
```
