# Dungeon Loadout

A Slay-the-Spire-style roguelike with **gear + talents** (classic D&D fantasy) instead of cards. Built with **Godot 4.3**, designed to ship as a browser game.

Current state: v2 vertical slice — branching map (Battle → Blacksmith+Shop or Skill Point → Boss → Win/Lose), 2–5 minute runs.

## Run it

1. Install [Godot 4.3](https://godotengine.org/download) (standard build, not .NET).
2. Clone this repo, open Godot, **Import** → select `project.godot`.
3. Press **F5** to play.

## Web export

Project → Export → Web (preset in `export_presets.cfg`), or headless:

```
godot --headless --export-release "Web" export/index.html
```

`export/` is git-ignored (build output only).

## Layout

```
project.godot
scenes/    boot, map, combat, shop_smith, skill_pick, result
scripts/   scene scripts + combat_state / run_state / enemy_data
docs/      design overview, slice brief, migration + implementation notes
```

Extra docs: `SLICE_BRIEF.md`, `V2_MIGRATION.md`, `IMPLEMENTATION_NOTES.md`, `docs/VERTICAL_SLICE_OVERVIEW.md` (previous README).

## v3 Stage A (LOOP_SPEC v3 section 0)

- Starting HP 36 (max and current); Bone Warden HP 33 (LOOP_SPEC v3.1).
- Enrage: from the start of player turn 7 in every fight (bosses included), each enemy deals +2 damage on all attacks, stacking each turn (+2 on turn 7, +4 on turn 8, ...), no cap.
- Intent labels show the enraged value; enemies show a red "Enraged +N" badge; a one-line toast appears on turn 7.
- Input lock (14e564c) and enemy-turn re-entry guard (c2dab71) retained; all v2.3 behavior unchanged.

## v3.1 Stage B (LOOP_SPEC v3.1 sections 1-3, Act 1 only)

- Act 1 map generator (`scripts/map_gen.gd`): 6 rows + boss, 2-3 nodes per row (row 6: 2 Rests), 1-2 non-crossing links per node; whole-map counts Battle 6-7, Elite 1-2, Skill Point 2, Shop+Smith 2, Rest 2-3 (v3.2).
- Rest node: heal 30% max HP (11 at 36) or Train (+1 rank to the talent you have; rank 2 = Bloodied Edge 15 / Iron Posture max(6, Strike/2) dmg + 4 Block, rank 2 +2 dmg (v3.3)).
- Act 1 enemies: Crypt Rat x2, Skeleton, Cultist, Elite Ghoul (Rend + Bleed), Bone Warden 33. Non-boss intent cycles start at a random point.
- Weapons: 12 items across Common/Uncommon/Rare/Legendary (`scripts/gear_data.gd`). Battle drop 40% (70/25/5), Elite always (Uncommon 75 / Rare 25), take-or-skip. Shop: 2 weapons (50/35/15; Common 30g), heal 10 HP for 20g (max 2 per visit), Hone +2 once per weapon for 20g.
- Gold: Battle 30-40, Elite 60, Boss 100 (v3.2).
- Fix: Block is consumed hit by hit (Guard 5 vs two Rats blocks 5 in total, not 5 per hit).
- QA: `index.html?seed=N` fixes the run seed; `&qa=1` prints DL* telemetry lines to the browser console.
