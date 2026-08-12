# Minecraft Server & Mod Configuration Design Specification

## Overview
This design specification defines the automated configuration architecture for the Minecraft Fabric 26.2 (1.21.4) server using a dedicated PowerShell script [`script/CONFIGURE_SERVER.ps1`](file:///c:/dev/minecraft/script/CONFIGURE_SERVER.ps1).

The configuration script programmatically modifies `server.properties` and all mod configuration files inside `D:\Games\minecraft-server\config\`.

---

## 1. Core Server Configuration (`server.properties`)

| Setting | Value | Rationale |
| :--- | :--- | :--- |
| `motd` | `\u00A76Hustisya Para Kay Rene \u00A77| \u00A7aSurvival` | Clean MOTD without version text |
| `level-name` | `hustisya para kay rene` | Retains existing world |
| `difficulty` | `hard` | Survival gameplay challenge |
| `online-mode` | `false` | Support for offline/custom client connections |
| `view-distance` | `10` | Render distance |
| `simulation-distance` | `10` | Ticking simulation distance |
| `max-players` | `20` | Concurrent player capacity |

*Note: Server environment target is Fabric game version **26.2** (Minecraft 1.21.4).*

---

## 2. Quality of Life (QoL) Mod Settings

### A. Universal Graves (`config/universal-graves/config.json`)
* `protection_time`: `1800` seconds (30 minutes of owner-only access).
* `grave_despawn_time`: `-1` (graves never despawn).
* `item_retrieval`: 1-tap right click retrieval enabled.

### B. Tree Harvester (`config/treeharvester.json5`)
* `fastLeafDecay`: `true` (leaves decay instantly when bottom trunk log is broken).
* `enableWikiLogInstantlyDecay`: `true`.

### C. Night Sleep Gamerule (`gameRules`)
* `playersSleepingPercentage`: `0` (1 player sleeping in a bed skips the night).

---

## 3. Immersion & Social Mods

### A. Server-Side Horror (`config/serversidehorror.json`)
* **Ghost Starers**: Restricted exclusively to `Herobrine` (`starer_list = ["Herobrine"]`).
* **Player Heads**: Disabled (`heads_from_list_enable = false`, `random_heads_enable = false`).
* **Increased Frequency**:
  * `fake_steps_chance`: `150000` (common footstep sounds)
  * `fake_mining_chance`: `150000` (common mining sounds)
  * `scary_sound_chance`: `250000` (common ambient sound effects)
* **Custom Sign Texts**:
  * `"TABANGI KO"`
  * `"YAWAAAAAA"`
  * `"nay iro mamatay unya"`
  * `"james biot"`
  * `"ben opaw"`
* **Custom Fake Joiners**:
  * `random_fake_joiner_list`: `["Herobrine;ReneBaterbonia"]`

### B. Simple Voice Chat (`config/voicechat/voicechat-server.properties`)
* `port`: `24454` (UDP)
* `voice_chat_distance`: `48.0` blocks
* 3D directional audio enabled.

### C. SkinsRestorer (`config/skinsrestorer/`)
* Offline skin fetching enabled for custom/cracked players.

---

## 4. New Server Features & Protection

### A. Anti-Xray (`config/antixray.json`)
* Obfuscates ores (diamond, gold, iron, emerald, ancient debris) from X-Ray mods and X-Ray resource packs.

### B. Player Tracking Compass (`config/playertracker.json`)
* Compass points toward nearest online player to enable locator/tracking mechanics.

### C. Styled Player List & Nicknames (`config/styledplayerlist/` & `config/stylednicknames/`)
* **TAB List Format**:
  * Header: `§6Hustisya Para Kay Rene §7| §aSurvival`
  * Player Row: `[${lvl}] ${name} (Deaths: ${deaths} | Playtime: ${playtime} | Ping: ${ping}ms)`
* **Nicknames**: `/nick` enabled for custom colored names.

---

## 5. Script Architecture (`script/CONFIGURE_SERVER.ps1`)

The script will be located at [`script/CONFIGURE_SERVER.ps1`](file:///c:/dev/minecraft/script/CONFIGURE_SERVER.ps1) and will:
1. Locate `D:\Games\minecraft-server\server.properties` and `D:\Games\minecraft-server\config\`.
2. Safely parse and update key-value pairs in `server.properties`.
3. Update JSON & JSON5 configuration files for `universal-graves` (30min protection), `treeharvester`, `serversidehorror` (custom signs, Herobrine starer, no heads, common sounds), `voicechat`, `antixray`, `styledplayerlist` (with ping in ms), and `skinsrestorer`.
4. Report a clean success summary upon completion.
