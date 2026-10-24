# Creature sprite mapping (art/assets-v1, for Build to integrate)

Source: **Tiny Creatures 1.0** by Clint Bellanger (CC0 1.0), https://opengameart.org/content/tiny-creatures,
`tiny-creatures.zip` sha256 `b397566a1a0f9189dbeb1119a797e35d5985b587596b02f6631d1eacec40252d`.
License text: `art/creatures/License-Tiny-Creatures.txt` (verbatim copy of the zip's `License.txt`).

**Note:** the pack's `Tiles/tile_NNNN.png` files have an **opaque black background** (no alpha). The PNGs here
were cropped from the pack's `Tilemap/tilemap_packed.png` (it has alpha; sha256 `1fd68a84...ca81`). The opaque
pixels are identical to `Tiles/tile_NNNN.png` and only the background is transparent. They're 16x16, RGBA, untinted,
and use the Kenney Tiny Dungeon palette (no off-palette colours).

| Enemy id (`scripts/art.gd` ENEMIES) | Current stand-in (Tiny Dungeon tile + tint) | New file | Pack tile | Tint to remove |
|---|---|---|---|---|
| `enemy_skeleton` | 121 ghost, tint `#E8E2D0` | `art/creatures/skeleton.png` | tile_0002 (skeleton) | `#E8E2D0` → `Color(1, 1, 1)` |
| `enemy_wraith` | 121 ghost, tint `#C3A2F0` | `art/creatures/wraith.png` | tile_0005 (hooded wraith) | `#C3A2F0` → `Color(1, 1, 1)` |
| `enemy_troll` (elite) | 87 horned brute, tint `#8FD394` | `art/creatures/troll.png` | tile_0043 (troll) | `#8FD394` → `Color(1, 1, 1)` |
| `enemy_red_dragon` (boss) | 110 red horned beast, no tint | `art/creatures/red_dragon.png` | tile_0034 (red dragon) | none (already untinted) |

The pack's creatures face **right**. Combat enemies face the hero, so Build should set `flip_h = true`
(or `TextureRect.flip_h`) if the hero sits to the left or below. Same integer scales as now (x5, Dragon x7; portrait x8 / x12).

Build note: `Art.tex()` loads `res://art/tile_%04d.png` by number. These files need a path-based entry
(e.g. `ENEMIES` value `["res://art/creatures/skeleton.png", Color(1,1,1)]`, or a separate `CREATURE_FILES` dict).
After the first editor import, check that the generated `.import` uses `compress/mode=0` and `mipmaps/generate=false`,
like the other tiles.

## Suggested next (not copied yet; Design to approve)

| Enemy id | Current stand-in | Suggested Tiny Creatures tile | Why |
|---|---|---|---|
| `enemy_drowned_king` (boss) | 84 wizard, tint `#7FB4E8` | **tile_0097** (crowned undead king, teal face, dark robe; sha256 of `Tiles/` file `1efa54b9...a16f`) | A real crowned undead that reads as a king with no tint. Teal skin fits "drowned". |
| `enemy_death_knight` (elite) | 97 visored knight, tint `#B07A80` | tile_0098 (dark knight) | A proper dark knight, no tint |
| `enemy_drowned` | 108 ghoul, tint `#7FB4E8` (shares tile with Ghoul) | tile_0027 (blue-haired siren) or tile_0001 (zombie) | Stops sharing the Ghoul tile |

Remaining tinted stand-ins after this: Bog Witch (100, `#B8E0A0`), Golem (109, `#A9A4C0`), Drowned (108, `#7FB4E8`),
Death Knight (97, `#B07A80`), Drowned King (84, `#7FB4E8`). Index sheet of the whole pack: DL Art's box `/workspace/dl-art/candidates/tiny_creatures_index.png`.
