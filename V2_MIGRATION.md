# Migration to v2.1 - StS-Style Branching Map + Gold Retune

## Summary

Successfully updated dungeon_loadout from v1 (linear Camp flow) to v2 (StS-style branching map with gold economy), then v2.1 (gold retune 45→55).

## Key Changes

### Map System
- **Replaced:** Linear A→Camp→Boss
- **With:** Branching graph: Battle A → (Shop+Smith XOR Skill Point) → Boss
- **Behavior:** Player picks ONE middle node; sibling is greyed out and skipped for the run
- **UI:** Visual layers show branching clearly; completed nodes get checkmarks

### Economy System (New)
- Start with 0 gold
- Battle A win: +55 gold (v2.1 retune from 45)
- Gold displayed on map HUD and shop header
- Purchase system with `spend_gold()` validation

### Scene Changes
- **Removed:** `scenes/camp.tscn` and `scripts/camp_scene.gd`
- **Added:** 
  - `scenes/shop_smith.tscn` + `scripts/shop_smith_scene.gd`
  - `scenes/skill_pick.tscn` + `scripts/skill_pick_scene.gd`

### Shop + Smith Node (Combined Screen)
**Shop Panel:**
- Iron Longsword: 35 gold → Strike 6→9
- Shows "Sold Out" if already owned
- Disabled if insufficient gold

**Blacksmith Panel:**
- Hone Edge: 20 gold → Strike +2 (cumulative with Longsword)
- Requires weapon owned (disabled otherwise)
- Once per run

**Skip allowed:** Continue button lets player proceed without purchases

### Skill Point Node
- Same two talents (Bloodied Edge, Iron Posture)
- Free selection (no gold cost)
- Replaces old Camp talent modal

### Combat Updates
- Battle A win now gives +55 gold and returns to map (not auto-loot modal)
- Combat numbers unchanged (Rats HP 8×2, Boss HP 28)
- All combat mechanics preserved (Focus, Block, intents)

### RunState Additions
```gdscript
var gold: int = 0
var hone_edge_used: bool = false
var middle_node_choice: String = ""

func add_gold(amount: int)
func spend_gold(amount: int) -> bool
func hone_edge()
func choose_middle_node(node_id: String)
```

## Path Validation

Both paths are designed to be viable:

### Path A: Shop + Smith
- Can achieve Strike 11 (Longsword 35g + Hone 20g = 55g total)
- **v2.1:** 55g reward exactly covers both items
- Buy Longsword (35g) → 20g left → can afford Hone (20g) → Strike 11
- Or: Skip purchases, fight with fists Strike 6
- **No Skill button** (talent not picked)

### Path B: Skill Point
- Strike 6 (fists only)
- Has Skill ability (Bloodied Edge 8 dmg OR Iron Posture +8 Block)
- Free choice, no gold spent

### Boss Balance Check
**Bone Warden:** HP 28, intents Strike 7 → Strike 7 → Heavy 11 → repeat

**Player options:**
- Fists (6) + no Skill: 5 strikes to kill (28/6 = ~5), takes ~15 turns → tough but possible
- Longsword (9) + no Skill: 4 strikes to kill (28/9 = ~4), more manageable
- Longsword + Hone (11) + no Skill: 3 strikes to kill (28/11 = ~3), very comfortable
- Fists (6) + Skill (8 dmg): 6 + 8 = 14 per 2-action cycle, easier with offense
- Fists (6) + Skill (+8 Block): defensive sustain, slower but safer

All paths appear beatable with good play (Focus/Block management).

## Map UI Implementation

**Node states:**
```gdscript
match RunState.map_progress:
    0:  # Battle available
        battle.disabled = false
        middle nodes.disabled = true
        boss.disabled = true
    1:  # Battle done, choose middle
        battle.disabled = true, text += " ✓"
        both middle nodes.disabled = false
        boss.disabled = true
    2:  # Middle done, boss available
        battle.disabled = true, text += " ✓"
        chosen middle.disabled = true, text += " ✓"
        other middle.disabled = true, modulate = grey
        boss.disabled = false
```

## Testing Checklist

- [x] Map shows branching structure
- [x] Battle A gives +55 gold (v2.1)
- [x] Can choose Shop+Smith path
- [x] Can choose Skill Point path
- [x] Chosen node gets checkmark, other gets greyed
- [x] Boss unlocks after either middle node
- [x] Shop: prices and logic correct
- [x] Blacksmith: requires weapon, correct Strike bonus
- [x] Skill: free selection, both talents available
- [x] Play Again resets everything including gold and path choice
- [x] Second run can take different path

## Notes for Game Designer

### v2.1 Balance Change

1. **Shop path gold constraint (RESOLVED in v2.1):**
   - ~~45 gold earned, 55 gold needed for both items~~ → **Changed to 55 gold**
   - **v2.1:** 55g reward exactly covers Longsword (35g) + Hone (20g)
   - Player can now afford full upgrade path in one shop visit
   - Skipping purchases still allowed for challenge runs

2. **Boss difficulty with fists only:**
   - Strike 6 vs Boss HP 28 = ~5 hits
   - Boss deals 7/7/11 damage (25 dmg over 3 turns)
   - Player HP 30, Block clears each turn
   - **Might be too tight** without Skill or gear
   - Skill-only path should have Skill to compensate

3. **No upgrade path is punishing:**
   - If player chooses Shop but skips purchases, fights Boss with fists and no Skill
   - **Extremely difficult** unless player is very skilled
   - Map UI should suggest one path is gear, other is skill

### Suggested Playtest Questions

1. ~~Is 45 gold the right amount?~~ **RESOLVED: Changed to 55g in v2.1**
2. Is Boss beatable with Strike 6 and no Skill? (Skip-all case)
3. Does the branching feel like meaningful choice or forced scarcity?
4. Should middle nodes have any preview of what they offer?

## Files Modified

**Core State:**
- `scripts/run_state.gd` - Added gold, hone tracking, path choice

**Map:**
- `scenes/map.tscn` - Complete UI redesign for 3 layers
- `scripts/map_scene.gd` - Branching logic and node exclusion

**Combat:**
- `scripts/combat_scene.gd` - Gold reward after Battle A

**New Scenes:**
- `scenes/shop_smith.tscn` - Shop + Blacksmith combined
- `scripts/shop_smith_scene.gd` - Purchase validation and UI updates
- `scenes/skill_pick.tscn` - Talent selection
- `scripts/skill_pick_scene.gd` - Talent confirmation

**Removed:**
- `scenes/camp.tscn`
- `scripts/camp_scene.gd`

**Documentation:**
- `README.md` - Updated for v2 flow
- `IMPLEMENTATION_NOTES.md` - Complete rewrite for v2
- `V2_MIGRATION.md` - This file

## Implementation Quality

**Strengths:**
- Clean separation of Shop and Skill paths
- StS-style map visual works well
- Gold economy is straightforward
- Node exclusion logic is clear

**Potential Issues:**
- Map UI could be more visually appealing (currently just buttons and labels)
- No icons for node types (just emoji in text - ⚔️🔨⭐💀)
- Gold constraint might frustrate players who want both shop items
- No tutorial or hints about path differences

**Future Enhancements (out of scope for slice):**
- Visual node connections/paths between layers
- Animated transitions on map
- Preview of node rewards before entering
- More interesting Shop inventory (multiple items, trinkets)
- Blacksmith upgrades beyond Hone (e.g., add sockets, reforge)
- Skill tree with more talents
- Random map generation
