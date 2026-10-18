# Implementation Notes - dungeon_loadout (v2.1)

## Overview

Complete Godot 4.x implementation of the dungeon_loadout vertical slice v2.1, following the brief exactly. Features **StS-style branching map** with mutually exclusive middle nodes.

## Files Created

### Core Configuration
- `project.godot` - Godot 4.3+ project file with autoload for RunState
- `export_presets.cfg` - Web export preset (GL Compatibility, single-thread)
- `.gitignore` - Standard Godot ignores

### Scenes (6 total)
- `scenes/boot.tscn` - Title screen with "Enter the Crypt" and Begin button
- `scenes/map.tscn` - StS-style branching map with 4 nodes in 3 layers
- `scenes/combat.tscn` - Turn-based combat interface
- `scenes/shop_smith.tscn` - Combined Blacksmith + Shop screen
- `scenes/skill_pick.tscn` - Talent selection screen
- `scenes/result.tscn` - Win/lose screen with Play Again

### Scripts (9 total)
- `scripts/run_state.gd` - **Global singleton** managing player state, gold, gear, talents, path choice
- `scripts/combat_state.gd` - Combat logic, turn management, focus/block systems
- `scripts/enemy_data.gd` - Enemy resource class definition
- `scripts/boot_scene.gd` - Boot scene controller
- `scripts/map_scene.gd` - Map scene controller with branching logic and node exclusion
- `scripts/combat_scene.gd` - Combat UI controller, enemy spawning, gold rewards
- `scripts/shop_smith_scene.gd` - Shop + Blacksmith controller with purchase logic
- `scripts/skill_pick_scene.gd` - Skill Point selection controller
- `scripts/result_scene.gd` - Result screen controller

## Implementation Details

### Flow Verification (v2)

**Correct sequence:**
1. boot.tscn → map.tscn (map_progress = 0)
2. Battle node enabled → combat.tscn (spawns 2 rats)
3. Win → add_gold(55) → advance_map() → map.tscn (map_progress = 1)
4. **Path A:** Choose Shop+Smith → shop_smith.tscn → buy/hone/skip → advance_map() → map.tscn (map_progress = 2, middle_node_choice = "node_shop_smith")
   **Path B:** Choose Skill Point → skill_pick.tscn → pick talent → advance_map() → map.tscn (map_progress = 2, middle_node_choice = "node_skill")
5. Boss node enabled → combat.tscn (spawns Bone Warden)
6. Win/Lose → result.tscn
7. Play Again → boot.tscn (reset_run())

### Combat System

**Turn sequence:**
1. Player turn starts → clear Block, +1 Focus (capped at 2)
2. Player chooses action (Strike/Guard/Skill)
3. Action resolves with 0.3s delay
4. Check win/lose
5. Enemy turn → each living enemy executes intent with 0.5s delays between
6. Advance enemy turn counters (for intent cycling)
7. Check win/lose
8. Loop back to step 1

**Damage calculation:**
```gdscript
actual_damage = max(0, raw_damage - block)
```

**Focus system:**
- Starts at 1
- +1 at start of each player turn
- Capped at 2
- Skill actions cost 1 Focus

**Block system:**
- Persists through enemy turn
- Cleared at start of player turn (Slay the Spire style)
- Reduces incoming damage

### Enemy Patterns

**Crypt Rats (Combat A):**
```gdscript
{"type": "strike", "value": 4},
{"type": "strike", "value": 4},
{"type": "guard", "value": 3}
// Repeats
```

**Bone Warden (Boss):**
```gdscript
{"type": "strike", "value": 7},
{"type": "strike", "value": 7},
{"type": "heavy", "value": 11}
// Repeats
```

Intents are indexed by `enemy.turn_count % intent_pattern.size()`, so they cycle correctly.

### Economy System

**Gold tracking:**
- Starts at 0 (`RunState.gold = 0`)
- Battle A win: `RunState.add_gold(55)`
- Shop purchases: `RunState.spend_gold(amount)` returns bool
- Displayed on map HUD and shop header

### Gear System

**Iron Longsword:**
- Available in Shop for 35 gold
- Effect: `RunState.strike_damage = 9` (from base 6)
- UI: "Strike (9)" instead of "Strike (6)"
- Shows "Sold Out" if already owned
- Can skip purchase (fight Boss with fists Strike 6)

**Hone Edge (Blacksmith):**
- Costs 20 gold
- Requires weapon owned (`RunState.equipped_gear != ""`)
- Effect: `RunState.strike_damage += 2`
- Once per run (`RunState.hone_edge_used`)
- Longsword + Hone = Strike 11

### Talent System

**Implementation:**
```gdscript
func get_skill_effect() -> Dictionary:
    match selected_talent:
        "talent_bloodied_edge":
            return {"type": "damage", "value": 8}
        "talent_iron_posture":
            return {"type": "block", "value": 8}
        _:
            return {"type": "none", "value": 0}
```

- Available only at Skill Point node (free)
- Skill button hidden until talent selected (`has_skill = RunState.selected_talent != ""`)
- Costs 1 Focus when used
- Active immediately for Boss fight

**Path implications:**
- **Shop-only path:** Can have Strike 11 (Longsword + Hone) but no Skill → valid
- **Skill-only path:** Strike 6 (fists) but has Skill effect → valid
- Both paths must be beatable against Boss (HP 28, Strike 7/7/Heavy 11)

### UI Design

**Colors:**
- Boot/Result: Dark blue-grey (0.1, 0.1, 0.15)
- Map: Dark purple-grey (0.15, 0.12, 0.18)
- Combat: Dark grey-purple (0.12, 0.1, 0.14)
- Camp: Warm dark brown (0.18, 0.15, 0.12)
- Win result: Slight green tint
- Lose result: Slight red tint

**Button sizes:**
- Action buttons: 160×60px (well above 48px minimum)
- Enemy buttons: 200×120px
- Navigation buttons: 60px height minimum

**Enemy display:**
- HP bars shown as text: "HP: 8/8"
- Block shown when > 0: "Block: 3"
- Intents shown with emoji: ⚔ Strike, 🛡 Guard, 💀 Heavy
- Selected enemy highlighted with modulate (1.2, 1.2, 0.8)
- Dead enemies greyed out (0.5, 0.5, 0.5)

### Technical Considerations

**Godot 4.x compatibility:**
- Uses `@onready` for node references
- Uses `func _ready()` for initialization
- Uses `await` for delays and async flow
- Signal connections use `.connect()` or `[connection]` in .tscn
- Type hints where appropriate: `var enemies: Array[Enemy]`
- Class definitions use `class_name` for inner classes

**Web export ready:**
- Compatibility renderer (not Forward+ or Mobile)
- No threading (thread_support=false)
- All resources bundled
- Scales from 1280×720

**Touch-friendly:**
- Button targets ≥48px
- No keyboard requirements
- Mouse and touch both supported
- Click/tap for all interactions

### Map Branching Logic

**Node states by progress:**
- **progress = 0:** Battle enabled, middle nodes disabled, Boss disabled
- **progress = 1:** Battle completed (✓), both middle nodes enabled (choose one)
- **progress = 2:** Battle completed (✓), chosen middle node completed (✓), other middle node greyed out (0.5 opacity), Boss enabled

**Visual feedback:**
- Available: normal color, enabled
- Completed: checkmark suffix, disabled
- Skipped: grey modulate (0.5, 0.5, 0.5), disabled

## Validation Checklist (v2.1)

To verify the implementation works:

1. **Boot screen:**
   - [ ] Shows "Enter the Crypt" title
   - [ ] Has "Begin" button
   - [ ] Button leads to Map

2. **Map screen (initial):**
   - [ ] Shows "The Crypt" title
   - [ ] Shows HP: 30/30 and Gold: 0
   - [ ] Shows 3 layers vertically
   - [ ] Layer 1 (Battle): ⚔ Crypt Rats - enabled
   - [ ] Layer 2 (Choose One): Both disabled
     - 🔨 Blacksmith + Shop
     - ⭐ Skill Point
   - [ ] Layer 3 (Boss): 💀 Bone Warden - disabled

3. **Combat A (Rats):**
   - [ ] Shows 2 rat enemies, each HP: 8/8
   - [ ] Shows player stats: HP 30/30, Block 0, Focus 1/2
   - [ ] Shows enemy intents above each rat
   - [ ] Strike button shows "Strike (6)"
   - [ ] Guard button shows "Guard"
   - [ ] Skill button hidden (no talent yet)
   - [ ] Can select enemies by clicking
   - [ ] Strike deals 6 damage to selected enemy
   - [ ] Guard gives +5 Block to player
   - [ ] Player Focus increases to 2 on next turn
   - [ ] Player Block clears at start of player turn
   - [ ] Rats execute intents correctly
   - [ ] Win condition: both rats HP ≤ 0 → +55 gold → Map

4. **Map (after Battle A):**
   - [ ] Battle node: ⚔ Crypt Rats ✓ (disabled)
   - [ ] Gold: 55
   - [ ] Both middle nodes now enabled
   - [ ] Boss still disabled

5. **Path A: Blacksmith + Shop:**
   - [ ] Header shows Gold: 55
   - [ ] Shop panel: Iron Longsword, 35g, "Strike: 6 → 9"
   - [ ] Shop: Can Buy if 55g, button shows "Buy (35g)"
   - [ ] Blacksmith panel: Hone Edge, 20g, "Strike: +2"
   - [ ] Blacksmith: Disabled initially (no weapon), shows "Need weapon"
   - [ ] Buy Longsword → gold 20 → Hone button enabled "Hone Edge (20g)"
   - [ ] Can afford both (55 - 35 - 20 = 0) → full upgrade path available
   - [ ] Can Continue without buying → valid path (skip allowed)
   - [ ] After Continue → Map with progress = 2

6. **Path B: Skill Point:**
   - [ ] Shows "Choose a Talent"
   - [ ] Two talent cards side by side
   - [ ] Bloodied Edge: "Skill: Deal 8 damage to selected enemy, Costs 1 Focus"
   - [ ] Iron Posture: "Skill: Gain 8 Block, Costs 1 Focus"
   - [ ] Select one → Map with progress = 2

7. **Map (after middle node):**
   - [ ] Battle: ⚔ Crypt Rats ✓
   - [ ] Chosen node shows ✓
   - [ ] Other node greyed out (no ✓)
   - [ ] Boss enabled: 💀 Bone Warden
   - [ ] Player HP and Gold reflect current state

8. **Combat Boss (Bone Warden):**
   - [ ] Shows 1 enemy: Bone Warden HP: 28/28
   - [ ] Shows player stats with HP from previous combat
   - [ ] Shows enemy intents cycling through pattern
   - [ ] Strike button shows correct damage:
     - Fists only: "Strike (6)"
     - Longsword: "Strike (9)"
     - Longsword + Hone: "Strike (11)"
   - [ ] Skill button visible ONLY if talent picked
   - [ ] Skill costs 1 Focus (button disabled if Focus < 1)
   - [ ] Skill has correct effect based on talent (if picked)
   - [ ] Shop-only path: can win with Strike 11 and no Skill
   - [ ] Skill-only path: can win with Strike 6 and Skill
   - [ ] Win or lose → Result screen

9. **Result screen (Win):**
   - [ ] Shows "Crypt Cleared"
   - [ ] Shows "Victory!"
   - [ ] Green tint to background
   - [ ] Has "Play Again" button
   - [ ] Returns to Boot

10. **Result screen (Lose):**
   - [ ] Shows "Fallen"
   - [ ] Shows "Defeat..."
   - [ ] Red tint to background
   - [ ] Has "Play Again" button
   - [ ] Returns to Boot

11. **Second run (test branching):**
   - [ ] Play Again resets everything
   - [ ] Can take the OTHER middle node
   - [ ] Previous path choice doesn't persist

## Known Limitations

As per the brief, these are intentionally not implemented:
- Multi-act maps with random generation
- Elite enemies, events, or rest sites
- Multiple gear slots (armor, trinket) - only weapon
- Full talent trees - only two talents in slice
- Character classes
- Save/load system (each run is fresh)
- Audio (beyond mute-safe design)
- Detailed tutorials
- Portal SDK integration beyond stubs (ads, analytics, leaderboards)

## Testing Recommendations (v2.1)

1. **Play through both paths:**
   - **Path A:** Boot → Map → Rats (+55g) → Shop+Smith (buy + hone) → Boss → Win
   - **Path B:** Boot → Map → Rats (+55g) → Skill Point (pick talent) → Boss → Win
   - Verify all numbers match the brief

2. **Test economic edge cases:**
   - Buy Longsword (35g) → 20g remaining → can afford Hone (20g) → Strike 11
   - Buy both items (55g total) → 0g remaining → full upgrade
   - Skip all purchases (fight Boss with fists) → 55g unused
   - Hone requires weapon (button disabled without)

3. **Test path exclusion:**
   - Choose Shop → Skill node greyed out
   - Choose Skill → Shop node greyed out
   - Second run: can choose the other path

4. **Test combat balance:**
   - Boss (HP 28, Strike 7/7/Heavy 11) vs Strike 6 only
   - Boss vs Strike 9 (Longsword) no Skill
   - Boss vs Strike 11 (Longsword + Hone) no Skill
   - Boss vs Strike 6 + Skill (either talent)
   - All should be winnable with good play

5. **Test UI/UX:**
   - Touch targets are large enough (≥48px)
   - Branching map is clear
   - Gold display on map and shop
   - Text is readable
   - Turn flow is clear
   - Intents make sense

6. **Test web export:**
   - Loads quickly (<5s to play)
   - Runs smoothly in browser
   - No threading issues
   - Scales correctly

## Next Steps for Developer

1. Open project in Godot 4.3+
2. Test in editor (F5)
3. Verify all checklist items above
4. Export to web and test in browser
5. If any issues found, they should be minor tweaks to timing or UI layout

## Code Quality Notes

- **Modular:** Combat logic separated from UI
- **Clean:** No debug prints left in code
- **Documented:** README explains all systems
- **Maintainable:** Easy to add new enemies, gear, or talents
- **Scalable:** Foundation ready for expansion beyond slice
