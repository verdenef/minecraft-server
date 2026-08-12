# ==============================================================================
# MINECRAFT SERVER & MOD CONFIGURATOR SCRIPT (Fabric 26.2 / 1.21.4)
# ==============================================================================

Write-Host "`n[*] Starting Minecraft Server & Mod Configuration..." -ForegroundColor Cyan

$serverDir = "D:\Games\minecraft-server"
$propFile = Join-Path -Path $serverDir -ChildPath "server.properties"
$configDir = Join-Path -Path $serverDir -ChildPath "config"

if (-not (Test-Path -Path $serverDir)) {
    Write-Host "[ERROR] Minecraft server directory not found at $serverDir" -ForegroundColor Red
    return
}

# ------------------------------------------------------------------------------
# 1. Core Server Properties (server.properties)
# ------------------------------------------------------------------------------
if (Test-Path -Path $propFile) {
    Write-Host "[*] Configuring server.properties..." -ForegroundColor Cyan
    $props = Get-Content -Path $propFile
    $newProps = @()
    foreach ($line in $props) {
        if ($line.StartsWith("motd=")) {
            $newProps += 'motd=\u00A76Hustisya Para Kay Rene \u00A77| \u00A7aSMP'
        } elseif ($line.StartsWith("difficulty=")) {
            $newProps += "difficulty=hard"
        } elseif ($line.StartsWith("online-mode=")) {
            $newProps += "online-mode=false"
        } elseif ($line.StartsWith("view-distance=")) {
            $newProps += "view-distance=10"
        } elseif ($line.StartsWith("simulation-distance=")) {
            $newProps += "simulation-distance=10"
        } elseif ($line.StartsWith("max-players=")) {
            $newProps += "max-players=20"
        } else {
            $newProps += $line
        }
    }
    $newProps | Set-Content -Path $propFile -Encoding UTF8
    Write-Host " -> server.properties updated!" -ForegroundColor Green
}

# ------------------------------------------------------------------------------
# 2. Universal Graves (config/universal-graves/config.json)
# ------------------------------------------------------------------------------
$gravesDir = Join-Path -Path $configDir -ChildPath "universal-graves"
if (-not (Test-Path -Path $gravesDir)) { New-Item -ItemType Directory -Path $gravesDir -Force | Out-Null }
$gravesConfig = Join-Path -Path $gravesDir -ChildPath "config.json"
$gravesObj = @{
    "protection_time" = 1800
    "grave_despawn_time" = -1
    "item_retrieval" = "ONE_TAP"
}
$gravesObj | ConvertTo-Json -Depth 5 | Set-Content -Path $gravesConfig -Encoding UTF8
Write-Host " -> Universal Graves config updated (30m protection, no despawn)!" -ForegroundColor Green

# ------------------------------------------------------------------------------
# 3. Tree Harvester (config/treeharvester.json5)
# ------------------------------------------------------------------------------
$treeConfig = Join-Path -Path $configDir -ChildPath "treeharvester.json5"
$treeContent = @"
{
  "fastLeafDecay": true,
  "enableWikiLogInstantlyDecay": true
}
"@
$treeContent | Set-Content -Path $treeConfig -Encoding UTF8
Write-Host " -> Tree Harvester config updated (instant leaf decay enabled)!" -ForegroundColor Green

# ------------------------------------------------------------------------------
# 4. Server-Side Horror (config/serversidehorror.json)
# ------------------------------------------------------------------------------
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
        Write-Host " -> Server-Side Horror config updated (custom signs & Herobrine)!" -ForegroundColor Green
    } catch {
        Write-Host "[WARNING] Could not parse serversidehorror.json: $_" -ForegroundColor Yellow
    }
}

# ------------------------------------------------------------------------------
# 5. Simple Voice Chat (config/voicechat/voicechat-server.properties)
# ------------------------------------------------------------------------------
$voiceDir = Join-Path -Path $configDir -ChildPath "voicechat"
if (-not (Test-Path -Path $voiceDir)) { New-Item -ItemType Directory -Path $voiceDir -Force | Out-Null }
$voiceConfig = Join-Path -Path $voiceDir -ChildPath "voicechat-server.properties"
$voiceProps = @"
port=24454
voice_chat_distance=48.0
"@
$voiceProps | Set-Content -Path $voiceConfig -Encoding UTF8
Write-Host " -> Simple Voice Chat config updated (port 24454, 48b range)!" -ForegroundColor Green

# ------------------------------------------------------------------------------
# 6. Styled Player List (config/styledplayerlist/config.json)
# ------------------------------------------------------------------------------
$tabDir = Join-Path -Path $configDir -ChildPath "styledplayerlist"
if (-not (Test-Path -Path $tabDir)) { New-Item -ItemType Directory -Path $tabDir -Force | Out-Null }
$tabConfig = Join-Path -Path $tabDir -ChildPath "config.json"
$tabObj = @{
    "header" = "§6Hustisya Para Kay Rene §7| §aSMP"
    "player_list_name" = "[${lvl}] ${name} (Deaths: ${deaths} | Playtime: ${playtime} | Ping: ${ping}ms)"
}
$tabObj | ConvertTo-Json -Depth 5 | Set-Content -Path $tabConfig -Encoding UTF8
Write-Host " -> Styled Player List config updated (ping in ms & statistics)!" -ForegroundColor Green

Write-Host "`n[SUCCESS] Minecraft Server & Mod Configuration complete!" -ForegroundColor Green
Write-Host ""
Pause
