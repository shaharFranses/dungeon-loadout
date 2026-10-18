# dungeon_loadout - Vertical Slice Brief v2.3

## Overview

A minimal turn-based dungeon crawler browser game focused on build decisions (Slay the Spire-inspired).

**Version:** 2.3  
**Platform:** Web (Godot 4.x)  
**Timeline:** Implemented and playable

## Core Loop

1. **Boot** → Begin button
2. **Map** → Choose path through branching nodes
3. **Battle A (Crypt Rats)** → Earn 55 gold
4. **Choose One:**
   - **Blacksmith + Shop** → Buy gear (Iron Longsword 35g) and/or Hone Edge service (20g)
   - **Skill Point** → Pick one talent (free)
5. **Boss Battle (Bone Warden)** → Use your build
6. **Result** → Win or Lose → Play Again

## Combat System

**Turn-based, single hero vs enemies:**

- **Hero stats:** HP 30, Block (temp), Focus (resource)
- **Actions:** Strike, Guard, Skill (if talent picked)
- **Focus system:** Starts at 1, +1 each turn (max 2), spent on Skills

**Block mechanics:**
- Player block cleared at start of player turn
- Enemy block cleared at start of that enemy's turn
- Guard action gives +5 Block

**Damage calculation:**
```
actual_damage = max(0, raw_damage - block)
```

## Battle A: Crypt Rats

**2 Rats, each:**
- HP: 8
- Pattern: Strike 4 → Strike 4 → Guard +3 (repeats)

**Reward:** 55 gold

## Boss Battle: Bone Warden

**Single enemy:**
- HP: 28
- Pattern: Strike 7 → Strike 7 → Heavy 11 (repeats)

## Economy

**Gold:** 55 from Battle A

**Shop items:**
- **Iron Longsword:** 35 gold → Strike damage 6 → 9

**Blacksmith services:**
- **Hone Edge:** 20 gold, requires weapon → Strike damage +2 (once per run)

**Optimal path:** Longsword (35g) + Hone Edge (20g) = Strike 11 damage

## Talents (v2.3)

**Free choice at Skill Point node (mutually exclusive with Shop):**

### Bloodied Edge
- **Effect:** Skill deals 11 damage to selected enemy
- **Cost:** 1 Focus

### Iron Posture
- **Effect:** Skill deals Strike damage (current strike_damage) AND gives +6 Block
- **Cost:** 1 Focus

**Focus:** Starts at 1, gains +1 per player turn (capped at 2)

## Branching Map

**3 Layers (StS-style):**

1. **Layer 1:** Battle A (Crypt Rats) - always required
2. **Layer 2:** Choose ONE:
   - Blacksmith + Shop
   - Skill Point
3. **Layer 3:** Boss (Bone Warden) - always required

**Path exclusion:** Choosing one middle node locks out the other (greyed out, no checkmark).

## Technical Specs

- **Engine:** Godot 4.3+
- **Export:** Web (GL Compatibility, single-thread)
- **Resolution:** 1280×720 base, scalable
- **Input:** Mouse/touch (no keyboard required)
- **Save:** No persistence (each run is fresh)

## Balance Goals

**All paths must be viable:**

1. **Shop-only path:** Strike 11 (Longsword + Hone), no Skill
2. **Skill-only path:** Strike 6 (fists), has Skill effect
3. **Budget path:** Skip purchases, Strike 6, no Skill (hard mode)

Boss (HP 28) should be beatable with skilled play on any path.

## UI Requirements

- Clean, readable fonts (no emoji on web - causes font rendering issues)
- Large touch targets (≥48px)
- Clear intent display for enemies
- Status indicators (HP, Block, Focus)
- Map breadcrumb in window title during combat
- Plural-aware titles ("1 enemy" vs "N enemies")

## Win Conditions

- **Combat win:** All enemies HP ≤ 0, player HP > 0
- **Combat loss:** Player HP ≤ 0
- **Run complete:** Defeat Bone Warden

## Out of Scope (for v2.3)

- Multiple acts or floors
- Random map generation
- Elite enemies or events
- Rest sites or healing
- Character classes
- Multiple gear slots
- Artifact system
- Save/load system
- Audio
- Leaderboards

## Changes in v2.3

**From v2.2:**

1. **Bloodied Edge buffed:** 8 → 11 damage
2. **Iron Posture reworked:** Was "Gain 8 Block" → Now "Deal Strike damage AND gain 6 Block"
3. **UI cleanup:** Removed emoji glyphs (⚔️, 🛡️, 💀, 🔨, ⭐) to fix web font rendering
4. **UX fixes:**
   - Window title resets to "dungeon_loadout" when leaving combat
   - Auto-target next enemy when current target dies
   - Plural-aware combat title ("1 enemy" vs "N enemies")
5. **Talent card layout:** Fixed empty spacing in skill selection cards

**Focus verification:** Focus starts at 1 turn 1, gains +1 each turn, capped at 2 (unchanged from v2.2)

## Success Metrics

- Playable in browser (loads <5s, runs smoothly)
- Both paths feel distinct and viable
- Combat is tactical (Block timing, Focus spending)
- Run time: 3-5 minutes for experienced players
- Replayable (different paths, different outcomes)
