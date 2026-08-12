# Separate Client & Server-Only Mod Manifests Design

## 1. Overview
This design separates Minecraft mods into two dedicated manifest files to prevent clients from downloading unnecessary server-only mods while ensuring dedicated server instances receive all required client, shared, and server-side mods.

---

## 2. Manifest Architecture

### Manifest Files
1. **`script/server-mods.txt` (Client & Shared Manifest)**:
   - Contains all mods required or useful on the client side (e.g. `sodium`, `fabric-api`, `simple-voice-chat`, `iris`, `trade-cycling`).
   - Pushed to Git repository and shared with friends.

2. **`script/server-only-mods.txt` (Server-Only Manifest)**:
   - Contains mods that operate exclusively on the dedicated server (e.g. `tree-harvester`, secret administrative mods).
   - Ignored or tracked as server host configuration.

---

## 3. Script Logic & Synchronization Flow

### `Get-ModManifest` Function Upgrade
- Updated signature: `Get-ModManifest -FileName <string>`.
- Searches for local candidates matching `-FileName` (e.g. `server-mods.txt`, `server-only-mods.txt`).

### `Sync-ServerMods` Function Logic
1. Reads and registers mods from `server-mods.txt`.
2. Checks active profile `$script:ActiveProfile`:
   - **If `$script:ActiveProfile -eq "server"`**: Reads and registers mods from `server-only-mods.txt` in addition to `server-mods.txt`.
   - **If `$script:ActiveProfile -ne "server"` (Client/Main)**: Syncs only `server-mods.txt`.
3. Executes `ferium upgrade` to pull binary `.jar` files into the active instance mods directory.

---

## 4. Initial Mod Categorization

### `server-mods.txt` (31 Mods)
`fabric-api`, `journeymap`, `sodium`, `sodium-extra`, `entityculling`, `ferrite-core`, `lithium`, `iris`, `modmenu`, `zoomify`, `distanthorizons`, `bobby`, `appleskin`, `mouse-tweaks`, `shulkerboxtooltip`, `inventory-profiles-next`, `gamma-utils`, `slot-cycler`, `bridging-mod`, `sound-physics-remastered`, `clumps`, `simple-voice-chat`, `easy-shulker-boxes`, `stack-to-nearby-chests`, `krypton`, `jade`, `controlling`, `rightclickharvest`, `rei`, `jei`, `freecam`, `universal-graves`, `trade-cycling`.

### `server-only-mods.txt` (1 Mod + Future Server-Only Mods)
`tree-harvester`.
