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

## Stage C (LOOP_SPEC v3.3 sections 2-4)

- Three acts: The Crypt, Sunken Halls, Dragon's Vault, each with its own generated map, enemies, Elite and boss. Max HP is 36 / 48 / 60 in Acts 1 / 2 / 3 (LOOP_SPEC v3.4) and the full heal between acts goes to the new max; gold, gear and talents carry over. The run ends on death or after the Act 3 boss; the results screen shows acts cleared, gold earned and the final build.
- New enemy moves: multi-hit Strike, Hex (your next Strike -3), Regenerate, Summon (max 1), Tidal (ignores half your Block), Drain (heals the attacker).
- Gear slots: Weapon, Armor (Block at fight start, extra Guard Block), Trinket (one passive rule). 12 items per slot across Common/Uncommon/Rare/Legendary (`scripts/gear_data.gd`). Drops roll a random slot. Act 1-2 bosses offer a choice of 3 Rare+ items (Legendary 10%). The shop stocks one item per slot and adds Reinforce Armor (+2 Block, once per armor, 25g).
- Talents (`scripts/talent_data.gd`): Warrior, Guardian, Arcane, 4 talents each, 2 ranks. Your first pick is one of the 3 tree Skills and becomes the Skill button; later picks offer 3 non-maxed talents. Skill Points and Rest-Train give a point; Elites give a bonus pick.
- Shop heal shows the real amount ("Heal +3") and is disabled at full HP.
- Talent cards are top-aligned, so every title sits at the same height.
- QA: `?seed=N&qa=1&act=N` starts directly in Act N (1-3); `act` is only honoured with `qa=1`.

## Stage D (LOOP_SPEC v3.6 section 5: Renown, camp, Ascension)
- Renown per run = acts cleared x20 + elites killed x3, +20 for a win (v3.7 wording; same totals as x10 per act + x10 per boss). It is banked on the results screen, which now leads to the camp.
- Camp (before every run): spend Renown on unlocks only. Arcane talent tree 30; gear batches Sunken Armory and Dragon Hoard, 20 each (5 new items each, `batch` in `scripts/gear_data.gd`); Starting item 50 (pick 1 of 3 Commons, one per slot, before each run).
- Arcane is locked until bought: while locked, the first talent offer shows the 2 open Skills and Arcane passives never appear.
- Ascension: after your first win, choose a level in the camp. Each level adds +10% enemy HP (summons included), up to 5. Winning at your highest level opens the next one.
- Progress is saved in `window.localStorage` under `dungeon_loadout_meta_v1` (`scripts/meta_store.gd`; a `user://` file outside the browser). If storage is blocked, the camp says so and progress lasts for the session.
- QA: `&qa=1&meta=reset` wipes saved progress; `&qa=1&renown=N` sets unspent Renown.
- QA fixes: a dead enemy never acts (and Thorns killing a Rend attacker cancels its bleed); the Strike button shows one-off modifiers (e.g. "Whetstone Charm +5", "Hexed -3"); DLACTION logs Breath as `breath` (with `kind: heavy`).

## v3.7 final retune (LOOP_SPEC v3.7)
- Drowned King HP 58; Young Red Dragon HP 92 (other numbers unchanged).
- Shop heal: +10 HP for 20g, max 1 per visit (was 2).
- Results screen: Renown breakdown line by line (Acts cleared x20, Elites x3, Win +20, total), then your Renown balance and the cheapest unlock you don't own yet.
- QA logs: a dead enemy's HP is reported as 0 (was negative) in DLUI and DLACTION.enemy_hp.

### QA Thorns check (seed 20)
Open `index.html?seed=20&qa=1&meta=reset`. In fights press only Strike (never Skill, never click an enemy) and Skip every gear offer.
1. Begin, Start Run. Row 1: the left Battle (2 Crypt Rats); you end on 24/36. Skip, Continue.
2. Row 2: the left Skill Point, take Iron Posture. Row 3: Skill Point, take Thorns.
3. Row 4: Elite (Ghoul 26). Strike 3 times: Ghoul 26 -> 20 -> 17 (Thorns) -> 11 -> 8 (Thorns) -> 2.
4. On the Ghoul's third turn it uses Rend 4 and dies to Thorns on that hit: the fight ends in Victory at 6/36, no bleed follows and nothing acts after it.
Console: the last Ghoul `DLACTION` line has `"intent":"rend","enemy_hp_before":2,"enemy_hp":0,"died":true,"hp":[10,6]`.

## v3.8 combat feedback (LOOP_SPEC v3.8, COMBAT_FEEDBACK.md)

- Turn flow: "Your Turn" / "Enemy Turn" banners; all input (actions and targeting) is locked
  for the whole enemy phase and nothing is buffered. Enemies act one at a time, left to right
  (~0.6-0.7s each, 0.15s gap); burn ticks and block expiry resolve under the Enemy Turn banner.
- Feedback (tweens and popups only): lunge / hit shake, red -N HP popups with blue blocked
  amounts kept separate, Guard shield flash, red windup before heavy/tidal, summon puff,
  Burn / Bleed / Thorns tick popups, Enrage vignette pulse, player hit flash, trailing HP bars,
  acting enemy's intent highlighted, 2-line combat log, 1x/2x speed toggle (saved in meta).
- Popups show real HP lost (overkill clamped); player HP clamps to 0 on death (HUD, DLEND,
  end screen).
- QA: `anim=fast` (x0.1) and `anim=off` URL flags; DLPHASE / DLLOG / DLPOP qa logs.
