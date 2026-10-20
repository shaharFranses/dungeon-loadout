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
