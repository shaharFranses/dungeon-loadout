# dungeon_loadout

A browser-based dungeon crawler inspired by Slay the Spire, built in Godot 4.x. Power comes from **gear + talents** in classic D&D fantasy — not cards or artifacts.

## Vertical Slice Overview (v2)

This playable slice proves a short **StS-style branching map** end-to-end:
- **Battle → (Blacksmith+Shop XOR Skill Point) → Boss → Win/Lose**
- Target session: **2–5 minutes**
- Designed to land in play <5s after load

## Flow

1. **Boot** → Title screen "Enter the Crypt" with Begin button
2. **Map** → StS-style branching graph:
   ```
            START
              |
         [Battle A]
          /        \
[Blacksmith+Shop]  [Skill Point]
          \        /
           [Boss]
   ```
   - Pick ONE middle node (sibling greyed/skipped)
   - Completed nodes show checkmark, no re-enter
   - Boss unlocks after middle layer
3. **Win** → "Crypt cleared" + Play again
4. **Lose** (HP ≤ 0) → "Fallen" + Play again

## Combat System

**Turn-based combat:**
- Player acts first each turn
- **Actions:** Strike / Guard / Skill
- **Resources:**
  - HP: starts at 30
  - Focus: starts at 1, max 2, +1 at start of each player turn
  - Block: clears at start of player turn (Slay the Spire style)
- **Damage calculation:** max(0, hit - Block); leftover Block persists until cleared

### Action Details

| Action | Effect |
|--------|--------|
| Strike | Deal 6 damage (9 with Iron Longsword) |
| Guard | Gain 5 Block |
| Skill | Costs 1 Focus; effect depends on chosen talent |

### Enemies

**Combat A - Crypt Rats:**
- 2× Rat (HP: 8 each)
- Intent cycle: Strike 4 → Strike 4 → Guard +3 → repeat

**Boss - Bone Warden:**
- HP: 28
- Intent cycle: Strike 7 → Strike 7 → Heavy 11 → repeat
- Enemy intents are telegraphed one turn ahead with icons

## Economy

- Start with **0 gold**
- **Battle A** win: **+55 gold** → return to map
- Gold shown on map HUD and shop

## Blacksmith + Shop (One Node)

**Shop:**
- **Iron Longsword** — 35 gold → Strike 6→9
- Shows "Sold Out" if already owned
- Flavor: "Not fancy. Cuts rats."

**Blacksmith:**
- **Hone Edge** — 20 gold (requires weapon owned)
- Strike +2 for rest of run (9→11 with Longsword)
- Once per run

Can skip purchases (Continue button) — valid to fight Boss with fists or without upgrades.

## Skill Point (Node)

**Choose one talent** (free):

| Talent | Effect |
|--------|--------|
| **Bloodied Edge** | Skill: Deal 8 damage to selected enemy |
| **Iron Posture** | Skill: Gain 8 Block |

- Skill button hidden until talent is picked
- Shop-only runs: gear but no Skill
- Skill-only runs: fists + Skill
- Both paths must be beatable

## Technical Specifications

- **Engine:** Godot 4.x (tested with 4.3)
- **Renderer:** Compatibility (GL Compatibility for web export)
- **Resolution:** 1280×720 logical, scales to iframe
- **Input:** Mouse + Touch support
- **Export target:** Single-thread web export

## How to Run

### In Godot Editor

1. **Install Godot 4.3+** (with Compatibility renderer support)
   - Download from: https://godotengine.org/download
2. **Open the project:**
   - Launch Godot
   - Click "Import"
   - Navigate to this folder and select `project.godot`
   - Click "Import & Edit"
3. **Run the game:**
   - Press F5 or click the Play button in top-right
   - The game starts at `scenes/boot.tscn`

### Web Export

1. **Set up HTML5 export template:**
   - In Godot, go to Editor → Manage Export Templates
   - Download templates for your Godot version
2. **Configure export preset:**
   - Project → Export
   - Add → HTML5
   - Set these options:
     - **Renderer:** GL Compatibility
     - **Thread Support:** Disabled (for maximum browser compatibility)
   - Click "Export Project"
   - Choose output folder and filename (e.g., `build/index.html`)
3. **Serve locally for testing:**
   ```bash
   cd build
   python3 -m http.server 8000
   ```
   - Open browser to http://localhost:8000

### Manual Export Preset Setup

If the export preset doesn't exist, create `export_presets.cfg`:

```ini
[preset.0]

name="Web"
platform="Web"
runnable=true
dedicated_server=false
custom_features=""
export_filter="all_resources"
include_filter=""
exclude_filter=""
export_path="./build/index.html"
encryption_include_filters=""
encryption_exclude_filters=""
encrypt_pck=false
encrypt_directory=false

[preset.0.options]

custom_template/debug=""
custom_template/release=""
variant/extensions_support=false
variant/thread_support=false
vram_texture_compression/for_desktop=true
vram_texture_compression/for_mobile=false
html/export_icon=true
html/custom_html_shell=""
html/head_include=""
html/canvas_resize_policy=2
html/focus_canvas_on_start=true
html/experimental_virtual_keyboard=false
progressive_web_app/enabled=false
progressive_web_app/offline_page=""
progressive_web_app/display=1
progressive_web_app/orientation=0
progressive_web_app/icon_144x144=""
progressive_web_app/icon_180x180=""
progressive_web_app/icon_512x512=""
progressive_web_app/background_color=Color(0, 0, 0, 1)
```

## Project Structure

```
dungeon_loadout/
├── scenes/
│   ├── boot.tscn        # Title screen
│   ├── map.tscn         # StS-style branching map
│   ├── combat.tscn      # Turn-based combat
│   ├── shop_smith.tscn  # Blacksmith + Shop combined
│   ├── skill_pick.tscn  # Talent selection
│   └── result.tscn      # Win/lose screen
├── scripts/
│   ├── run_state.gd     # Global game state (autoload)
│   ├── combat_state.gd  # Combat logic and turn management
│   ├── enemy_data.gd    # Enemy resource class
│   └── [scene scripts]  # One script per scene
├── project.godot        # Godot project config
└── README.md
```

## Implementation Notes

### Faithful to Brief (v2)

All numbers and mechanics match the vertical slice brief v2.1:
- HP, Focus, Block values as specified
- Enemy HP and intent patterns exact
- Gold economy: 0 start, +55 from Battle A
- Shop prices: Longsword 35g, Hone Edge 20g
- Gear and talent effects precise
- StS-style branching map with node exclusion

### Out of Scope (Not Implemented)

As per the brief, the following are intentionally excluded:
- Branching map paths
- Shops or merchants
- Multi-slot gear system
- Full talent trees
- Character classes
- Relics/artifacts/cards
- Multiplayer
- Detailed tutorials
- Portal SDK integration (beyond stub hooks)

### UI Considerations

- Resolution designed for 1280×720, readable at ~960×540
- Button hit targets ≥48px for touch-friendly interaction
- Simple colored panels serve as art placeholders
- Enemy intents shown with emoji icons (⚔ sword, 🛡 shield, 💀 skull)

## Acceptance Checklist (v2.1)

The slice is complete when you can:
1. ✓ Begin → Map shows StS-style branch
2. ✓ Clear Battle A → gold 55
3. ✓ Choose Blacksmith+Shop OR Skill Point (sibling skipped)
4. ✓ Shop path: buy Longsword / hone OR skip
5. ✓ Skill path: pick one talent
6. ✓ Boss → Win or Lose → Play Again
7. ✓ Second run can take the other branch

## Development

To modify or extend:
- **Add new enemies:** Edit enemy setup arrays in `combat_scene.gd`
- **Add gear/talents:** Extend `run_state.gd` and update Camp UI
- **Modify numbers:** All combat values are in `combat_state.gd` and `run_state.gd`
- **Change flow:** Edit scene transitions in each scene script

## License

Built as a vertical slice demonstration. All rights reserved.
