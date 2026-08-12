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
        }
        elseif ($line.StartsWith("difficulty=")) {
            $newProps += "difficulty=hard"
        }
        elseif ($line.StartsWith("online-mode=")) {
            $newProps += "online-mode=false"
        }
        elseif ($line.StartsWith("view-distance=")) {
            $newProps += "view-distance=10"
        }
        elseif ($line.StartsWith("simulation-distance=")) {
            $newProps += "simulation-distance=6"
        }
        elseif ($line.StartsWith("max-players=")) {
            $newProps += "max-players=20"
        }
        else {
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
    "protection_time"    = 1800
    "grave_despawn_time" = -1
    "item_retrieval"     = "ONE_TAP"
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
# Note: Lower chance number = occurs more frequently. Set *_enable to $true/$false.
# ------------------------------------------------------------------------------
$horrorConfig = Join-Path -Path $configDir -ChildPath "serversidehorror.json"

$horrorObj = [ordered]@{
    "grace_period"                       = 3
    "grace_period_applies_to_traps"      = $false

    # Ghost Starers
    "herobrine_starer_enable"            = $true
    "herobrine_starer_chance"            = 120000
    "starer_enable"                      = $true
    "starer_chance"                      = 420000
    "starer_list"                        = @("Herobrine")

    # Jumpscares
    "jumpscare_enable"                   = $true
    "jumpscare_chance"                   = 1080000

    # Fake Joiners
    "fake_joiner_enable"                 = $true
    "fake_joiner_chance"                 = 720000
    "random_fake_joiner_enable"          = $true
    "random_fake_joiner_chance"          = 720000
    "random_fake_joiner_list"            = @("Herobrine;ReneBaterbonia")

    # Audio & Ambient Scares
    "fake_steps_enable"                  = $true
    "fake_steps_chance"                  = 150000
    "fake_mining_enable"                 = $true
    "fake_mining_chance"                 = 150000
    "scary_sound_enable"                 = $true
    "scary_sound_chance"                 = 250000
    "scary_sound_list"                   = @(
        "minecraft:block.bell.resonate",
        "minecraft:block.bell.use",
        "minecraft:entity.tnt.primed",
        "minecraft:entity.generic.explode",
        "minecraft:entity.creeper.primed",
        "minecraft:entity.arrow.hit",
        "minecraft:item.trident.hit_ground",
        "minecraft:entity.polar_bear.ambient",
        "minecraft:entity.polar_bear.ambient_baby",
        "minecraft:item.crossbow.hit",
        "minecraft:entity.polar_bear.death",
        "minecraft:entity.polar_bear.warning",
        "minecraft:entity.dragon_fireball.explode",
        "minecraft:entity.splash_potion.break",
        "minecraft:entity.ghast.scream",
        "minecraft:entity.allay.death"
    )

    # Creepy Signs
    "random_signs_enable"                = $true
    "random_signs_chance"                = 500000
    "random_signs_texts"                 = @("TABANGI KO", "YAWAAAAAA", "nay iro mamatay unya", "james biot", "ben opaw", "i see you", "rene was here")

    # Torch Breaking & Modification
    "break_torches_enable"               = $true
    "break_torches_chance"               = 720000
    "replace_torches_enable"             = $true
    "replace_torches_chance"             = 720000

    # Weather & Night Length
    "random_lightning_enable"            = $true
    "random_lightning_chance"            = 1800000
    "long_night_enable"                  = $true
    "long_night_chance"                  = 75

    # Traps & Dungeon Spawns
    "setting_up_new_traps_enable"        = $true
    "setting_up_new_traps_chance"        = 1500000
    "traps_enable"                       = $true
    "joining_in_dungeon_enable"          = $true
    "joining_in_dungeon_chance"          = 140

    # Leaf Removal Horror Feature
    "removing_leaves_enable"             = $true
    "removing_leaves_chance"             = 2000000

    # High-Risk / Destructive Features (Disabled by Default)
    "burn_down_house_enable"             = $false
    "burn_down_house_chance_per_wake_up" = 100
    "joining_on_bedrock_enable"          = $false
    "joining_on_bedrock_chance"          = 70

    # Player Heads (Disabled as requested)
    "heads_from_list_enable"             = $false
    "heads_from_list_chance"             = 800000
    "heads_from_list_list"               = @("Herobrine")
    "random_heads_enable"                = $false
    "random_heads_chance"                = 800000

    # World Generation Features
    "old_villages_enable"                = $true
}

$horrorObj | ConvertTo-Json -Depth 10 | Set-Content -Path $horrorConfig -Encoding UTF8
Write-Host " -> Server-Side Horror config updated (all features & chances explicitly listed)!" -ForegroundColor Green

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
# 6. Styled Player List (config/styledplayerlist/config.json & styles/default.json)
# ------------------------------------------------------------------------------
$tabDir = Join-Path -Path $configDir -ChildPath "styledplayerlist"
if (-not (Test-Path -Path $tabDir)) { New-Item -ItemType Directory -Path $tabDir -Force | Out-Null }

$tabConfig = Join-Path -Path $tabDir -ChildPath "config.json"
$tabObj = [ordered]@{
    "config_version"               = 2
    "default_style"                = "default"
    "player"                       = [ordered]@{
        "modify_name"              = $true
        "modify_right_text"        = $true
        "modify_list_order"        = $false
        "modify_visibility"        = $false
        "passthrough"               = $false
        "hidden"                   = $false
        "format"                   = "%player:displayname%"
        "right_text"               = "<gray>Deaths: <red>%player:statistic deaths%</red> | Playtime: <gold>%player:statistic play_time%</gold> | Ping: <green>%player:ping%ms</green></gray>"
        "update_on_chat_message"   = $false
        "update_tick_time"         = 20
    }
    "client_show_in_singleplayer" = $true
}
($tabObj | ConvertTo-Json -Depth 5).Replace('\u003c', '<').Replace('\u003e', '>') | Set-Content -Path $tabConfig -Encoding UTF8

$stylesDir = Join-Path -Path $tabDir -ChildPath "styles"
if (-not (Test-Path -Path $stylesDir)) { New-Item -ItemType Directory -Path $stylesDir -Force | Out-Null }
$defaultStyle = Join-Path -Path $stylesDir -ChildPath "default.json"
$styleObj = [ordered]@{
    "style_name"          = "Default"
    "update_tick_time"    = 20
    "list_header"         = @(
        "",
        "<gold><bold>Hustisya Para Kay Rene</bold></gold> | <green>SMP</green>",
        ""
    )
    "list_footer"         = @(
        "",
        "<gray>TPS: %server:tps_colored% | Ping: <color:#ffba26>%player:ping%ms</color></gray>",
        ""
    )
    "hidden_in_commands"  = $false
}
$styleObj | ConvertTo-Json -Depth 5 | Set-Content -Path $defaultStyle -Encoding UTF8
Write-Host " -> Styled Player List config updated (header, footer, deaths, playtime & ping in ms)!" -ForegroundColor Green

# ------------------------------------------------------------------------------
# 7. Styled Nicknames (config/styled-nicknames.json)
# ------------------------------------------------------------------------------
$nickConfig = Join-Path -Path $configDir -ChildPath "styled-nicknames.json"
if (Test-Path -Path $nickConfig) {
    try {
        $nObj = Get-Content -Path $nickConfig -Raw | ConvertFrom-Json
        $nObj.allowByDefault = $true
        $nObj.changeDisplayName = $true
        $nObj.changePlayerListName = $true
        $nObj.allowLegacyFormatting = $true
        $nObj.nicknameFormat = '${nickname}'
        $nObj.nicknameFormatColor = '${nickname}'
        if ($null -ne $nObj.defaultEnabledFormatting) {
            $nObj.defaultEnabledFormatting.color = $true
            $nObj.defaultEnabledFormatting.gradient = $true
            $nObj.defaultEnabledFormatting.rainbow = $true
            $nObj.defaultEnabledFormatting.bold = $true
            $nObj.defaultEnabledFormatting.italic = $true
            $nObj.defaultEnabledFormatting.underline = $true
        }
        $nObj | ConvertTo-Json -Depth 10 | Set-Content -Path $nickConfig -Encoding UTF8
        Write-Host " -> Styled Nicknames config updated (colors, gradients & TAB list sync enabled)!" -ForegroundColor Green
    } catch {
        Write-Host "[WARNING] Could not parse styled-nicknames.json: $_" -ForegroundColor Yellow
    }
}

# ------------------------------------------------------------------------------
# 8. Distant Horizons Server Optimization (config/DistantHorizons.toml)
# ------------------------------------------------------------------------------
$dhConfig = Join-Path -Path $configDir -ChildPath "DistantHorizons.toml"
if (Test-Path -Path $dhConfig) {
    $dhContent = Get-Content -Path $dhConfig -Raw
    $dhContent = $dhContent.Replace("enableServerGeneration = true", "enableServerGeneration = false")
    $dhContent | Set-Content -Path $dhConfig -Encoding UTF8
    Write-Host " -> Distant Horizons server generation offloaded to clients (eliminates tick lag)!" -ForegroundColor Green
}

# ------------------------------------------------------------------------------
# 9. Welcome Guide Datapack & Announcements (world/datapacks/server_guide)
# ------------------------------------------------------------------------------
$worldFolder = Join-Path -Path $serverDir -ChildPath "hustisya para kay rene"
$dpDir = Join-Path -Path $worldFolder -ChildPath "datapacks\server_guide"
$dpData = Join-Path -Path $dpDir -ChildPath "data"

if (-not (Test-Path -Path $dpDir)) {
    New-Item -ItemType Directory -Path (Join-Path -Path $dpData -ChildPath "minecraft\tags\function") -Force | Out-Null
    New-Item -ItemType Directory -Path (Join-Path -Path $dpData -ChildPath "server_guide\function") -Force | Out-Null
    New-Item -ItemType Directory -Path (Join-Path -Path $dpData -ChildPath "server_guide\advancement") -Force | Out-Null
}

$mcmeta = @'
{
  "pack": {
    "pack_format": 61,
    "description": "Hustisya Para Kay Rene SMP Interactive Welcome Guide Datapack"
  }
}
'@
$utf8NoBom = New-Object System.Text.UTF8Encoding($false)

[System.IO.File]::WriteAllText((Join-Path -Path $dpDir -ChildPath "pack.mcmeta"), $mcmeta, $utf8NoBom)
[System.IO.File]::WriteAllText((Join-Path -Path $dpData -ChildPath "minecraft\tags\function\load.json"), '{"values": ["server_guide:load"]}', $utf8NoBom)
[System.IO.File]::WriteAllText((Join-Path -Path $dpData -ChildPath "minecraft\tags\function\tick.json"), '{"values": ["server_guide:tick"]}', $utf8NoBom)

$loadMc = @'
scoreboard objectives add show_guide trigger "Show Server Guide"
scoreboard objectives add guide_timer dummy "Guide Timer"
scoreboard objectives add tip_index dummy "Tip Index"
tellraw @a [{"text":"[Server] ","color":"gold","bold":true},{"text":"Interactive Welcome Guide & 5-Min Tip Broadcaster Loaded!","color":"green"}]
'@
[System.IO.File]::WriteAllText((Join-Path -Path $dpData -ChildPath "server_guide\function\load.mcfunction"), $loadMc, $utf8NoBom)

$tickMc = @'
scoreboard players enable @a show_guide
execute as @a[scores={show_guide=1..}] run function server_guide:send_guide

scoreboard players add #server guide_timer 1
execute if score #server guide_timer matches 6000.. run function server_guide:broadcast_tip
'@
[System.IO.File]::WriteAllText((Join-Path -Path $dpData -ChildPath "server_guide\function\tick.mcfunction"), $tickMc, $utf8NoBom)

$broadcastMc = @'
scoreboard players set #server guide_timer 0
scoreboard players add #server tip_index 1
execute if score #server tip_index matches 7.. run scoreboard players set #server tip_index 1

# Tip 1: Skins
execute if score #server tip_index matches 1 run tellraw @a ["",{"text":"[TIP] ","color":"gold","bold":true},{"text":"Change your skin anytime! Type ","color":"yellow"},{"text":"/skin set <SkinName>","color":"aqua","bold":true,"clickEvent":{"action":"suggest_command","value":"/skin set "},"hoverEvent":{"action":"show_text","contents":"Click to use /skin"}},{"text":" or use a PNG link with /skin url <URL>","color":"yellow"}]

# Tip 2: Nicknames & Colors
execute if score #server tip_index matches 2 run tellraw @a ["",{"text":"[TIP] ","color":"gold","bold":true},{"text":"Customize your chat & TAB name color! Type ","color":"yellow"},{"text":"/nick set &aName","color":"green","bold":true,"clickEvent":{"action":"suggest_command","value":"/nick set &a"},"hoverEvent":{"action":"show_text","contents":"Click to use /nick"}},{"text":" or use gradients like <gradient:#ff4500:#ffa500>Name</gradient>!","color":"yellow"}]

# Tip 3: Universal Graves
execute if score #server tip_index matches 3 run tellraw @a ["",{"text":"[TIP] ","color":"gold","bold":true},{"text":"Died far from home? Your items are safe in a Grave for 30 minutes! Right-click 1-tap to retrieve everything.","color":"yellow"}]

# Tip 4: Tree Harvester & Farming
execute if score #server tip_index matches 4 run tellraw @a ["",{"text":"[TIP] ","color":"gold","bold":true},{"text":"Chop trees fast! Break the bottom log to fell the tree & decay leaves instantly. Right-click mature crops to harvest & auto-replant.","color":"yellow"}]

# Tip 5: Shulkers & Inventory Sorting
execute if score #server tip_index matches 5 run tellraw @a ["",{"text":"[TIP] ","color":"gold","bold":true},{"text":"Inventory Shortcuts: Right-click a Shulker Box directly inside your inventory to open it! Press [R] in inventory/chest to auto-sort.","color":"yellow"}]

# Tip 6: Keybinds & Navigation
execute if score #server tip_index matches 6 run tellraw @a ["",{"text":"[TIP] ","color":"gold","bold":true},{"text":"Controls: [J] Map | [B] Waypoint | [G] Fullbright | [C] Zoom | [F4] Freecam | [V] Voice Chat. Type ","color":"yellow"},{"text":"/trigger show_guide","color":"aqua","bold":true,"clickEvent":{"action":"run_command","value":"/trigger show_guide"}},{"text":" for full guide!","color":"yellow"}]
'@
[System.IO.File]::WriteAllText((Join-Path -Path $dpData -ChildPath "server_guide\function\broadcast_tip.mcfunction"), $broadcastMc, $utf8NoBom)

$sendGuideMc = @'
tellraw @s ["",{"text":"==================================================\n","color":"gold","bold":true},{"text":"        Welcome to Hustisya Para Kay Rene SMP!\n","color":"gold","bold":true},{"text":"==================================================\n","color":"gold","bold":true},{"text":" [Skins]          : ","color":"yellow","bold":true},{"text":"/skin set <SkinName>  ","color":"gray"},{"text":"[Click to Set Skin]\n","color":"green","bold":true,"clickEvent":{"action":"suggest_command","value":"/skin set "},"hoverEvent":{"action":"show_text","contents":"Click to open /skin command"}},{"text":" [Nicknames]      : ","color":"yellow","bold":true},{"text":"/nick set &aName ","color":"gray"},{"text":"[Click to Set Color]\n","color":"green","bold":true,"clickEvent":{"action":"suggest_command","value":"/nick set &a"},"hoverEvent":{"action":"show_text","contents":"Click to open /nick command"}},{"text":" [Universal Grave]: ","color":"yellow","bold":true},{"text":"30-min item protection on death (1-tap retrieval)\n","color":"gray"},{"text":" [Tree Harvester] : ","color":"yellow","bold":true},{"text":"Break bottom log to chop & decay leaves\n","color":"gray"},{"text":" [1-Player Sleep] : ","color":"yellow","bold":true},{"text":"Only 1 player needed to skip the night\n","color":"gray"},{"text":" [Shulker Open]   : ","color":"yellow","bold":true},{"text":"Right-click shulker in inventory | Shift to preview\n","color":"gray"},{"text":" [JourneyMap]     : ","color":"yellow","bold":true},{"text":"[J] Full Map | [B] Waypoints | [Ctrl+B] Quick Pin\n","color":"gray"},{"text":" [Utility Keys]   : ","color":"yellow","bold":true},{"text":"[G] Fullbright | [C] Zoom | [F4] Freecam | [V] Voice\n","color":"gray"},{"text":"==================================================\n","color":"gold","bold":true},{"text":"  Type ","color":"gray"},{"text":"/trigger show_guide","color":"aqua","bold":true,"clickEvent":{"action":"run_command","value":"/trigger show_guide"},"hoverEvent":{"action":"show_text","contents":"Click to re-open guide"}},{"text":" anytime in chat to re-open this guide!\n","color":"gray"},{"text":"==================================================","color":"gold","bold":true}]
scoreboard players reset @s show_guide
advancement revoke @s only server_guide:player_joined
'@
[System.IO.File]::WriteAllText((Join-Path -Path $dpData -ChildPath "server_guide\function\send_guide.mcfunction"), $sendGuideMc, $utf8NoBom)

$playerJoinedAdv = @'
{
  "criteria": {
    "requirement": {
      "trigger": "minecraft:tick"
    }
  },
  "rewards": {
    "function": "server_guide:send_guide"
  }
}
'@
[System.IO.File]::WriteAllText((Join-Path -Path $dpData -ChildPath "server_guide\advancement\player_joined.json"), $playerJoinedAdv, $utf8NoBom)

Write-Host " -> Interactive Welcome Guide Datapack installed & configured (UTF-8 No BOM)!" -ForegroundColor Green

Write-Host "`n[SUCCESS] Minecraft Server & Mod Configuration complete!" -ForegroundColor Green
Write-Host ""
Pause
