# Minecraft Server Guide & Announcement System Design Specification

## Overview
This design specification defines the in-game Player Guide & Announcement System for the Minecraft Fabric 26.2 (1.21.4) server.

The system provides multi-colored chat guides covering player customization, controls, storage, farming, and navigation through:
1. **Welcome Message (On Join)**: Displays a welcome header and feature overview upon joining.
2. **Periodic Auto-Broadcast**: Rotates tip categories every 15 minutes.
3. **On-Demand `/guide` Command**: Interactive chat guide menu accessible anytime.

---

## 1. Guide Topics & Command Reference

### A. Customization & Identity
* `/skin set <SkinName>` — Set skin to any player username (e.g. `/skin set Notch`).
* `/skin url <ImageURL>` — Set skin from a direct PNG image link.
* `/nick set <color>Name` — Change chat & TAB list name color (e.g. `/nick set &aAlex` or `/nick set <gradient:#ff4500:#ffa500>Alex</gradient>`).
* `/nick reset` — Clear nickname.

### B. Voice Chat & Controls
* **Key `V`** — Simple Voice Chat menu (proximity volume, microphone settings, private voice groups).
* **Key `M`** — Mute/unmute microphone toggle.

### C. Storage & Inventory Shortcuts
* **Inventory Shulker Open**: Right-click a Shulker Box directly inside your inventory to open it without placing it down.
* **Shulker & Bundle Preview**: Hover over a Shulker Box or Bundle and hold `Shift` to inspect items inside.
* **Inventory Auto-Sort**: Press `R` (or middle-click) inside your inventory or chest to auto-sort items.
* **Quick Stack**: Click the **Quick Stack** button inside a chest to automatically deposit matching items into nearby chests.

### D. Survival & Farming QoL
* **Right-Click Harvest**: Right-click fully grown crops (Wheat, Carrots, Potatoes, Beetroot) to harvest & auto-replant in 1 click.
* **Tree Harvester**: Break the bottom trunk log of any tree to fell the entire tree and decay leaves instantly.
* **1-Player Night Sleep**: Only 1 player needs to sleep in a bed to skip the night.
* **Villager Trade Reroll**: Click the **Cycle Trades** button when trading with a Villager to reroll trades without breaking the workstation.
* **Universal Graves**: On death, a grave protects your items for 30 minutes. Right-click 1-tap to retrieve 100% of your items.

### E. Exploration & Visual Utilities
* **Compass Player Dots**: Hold a **Compass** in main hand or off-hand to render online player locator dots on the top HUD bar.
* **JourneyMap**: `J` (Full Map), `B` (Waypoint Manager), `Ctrl + B` (Quick Waypoint).
* **Key `G`** — Toggle **Fullbright** (Full Gamma mode) on/off.
* **Key `C`** — Smooth **Zoom** in/out.
* **Key `F6`** — Toggle **Freecam** ghost camera mode.
* **Fast Bridging**: Look down at the edge of a block while walking forward to place blocks in front of you without sneaking.

---

## 2. Server Integration & Automated Configuration (`script/CONFIGURE_SERVER.ps1`)

The configuration script [`script/CONFIGURE_SERVER.ps1`](file:///c:/dev/minecraft/script/CONFIGURE_SERVER.ps1) will:
1. Configure `welcome-message` mod (`config/welcome-message.json` or `config/welcome-message.txt`) with the formatted server guide header.
2. Configure `styled-chat` (`config/styled-chat.json`) to register `/guide` and `/help` commands.
