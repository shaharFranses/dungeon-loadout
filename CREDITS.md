# Credits

All shipped art and fonts are CC0 (third-party CC0, or self-generated and released as CC0). Every source used (or evaluated) is listed here.

## 1. Kenney - Tiny Dungeon (1.0) - used

- Source: https://kenney.nl/assets/tiny-dungeon (kenney_tiny-dungeon.zip,
  sha256 c109438ab06f65fd80f9b2686a4cf9c7c11dc64444b47333ec71d602f8bb5fc7)
- License: Creative Commons Zero (CC0 1.0), http://creativecommons.org/publicdomain/zero/1.0/
  Full text: `art/License-Kenney-Tiny-Dungeon.txt` (whitespace-normalised copy of the pack's License.txt).
- Used: 41 of the 132 16x16 tiles, in `art/tile_NNNN.png` (unmodified; runtime nearest-neighbour
  integer scaling and palette tints only).

## 2. Kenney - Kenney Fonts ("Kenney Pixel") - used

- Source: https://kenney.nl/assets/kenney-fonts (kenney_kenney-fonts.zip,
  sha256 4e69a86eef3cd47e9d8207413868cd08bcddeb2dae4047dbd10362e2a7a16bac)
- License: Creative Commons Zero (CC0 1.0). Full text: `art/fonts/License-Kenney-Fonts.txt`.
- Used: `Kenney Pixel.ttf` only, shipped as `art/fonts/kenney_pixel.ttf`
  (sha256 174093d8b71aa808d7ffff70529c9087274515493add48134528c9136f621e92), the global UI font.

## 3. 0x72 - 16x16 DungeonTileset II (v1.7) - evaluated, NOT used

- Source: https://0x72.itch.io/dungeontileset-ii (0x72_DungeonTilesetII_v1.7.zip,
  sha256 a5b23341ebc831d7798bfb9666d864a08c079bb7aed18e3cf023a27d517c1512, downloaded 2026-10-20).
- The itch.io page metadata says CC0, and the archive has 16x16 skeleton frames
  (`frames/skelet_idle_anim_f0.png`, sha256 8e140a74ab56be33cb53280b0f773c9e31435c179405865f0adf5c356b4c99d5),
  but the download contains **no license file**: its only text file, `README`, covers tile layout
  and says nothing about licensing. The rule for this pass was "use it only if the license file in
  the download says CC0", so the Skeleton keeps the Tiny Dungeon stand-in. The pack has no dragon.

## 4. Clint Bellanger - Tiny Creatures (1.0) - used (art/assets-v1)

- Source: https://opengameart.org/content/tiny-creatures (file https://opengameart.org/sites/default/files/tiny-creatures.zip,
  sha256 b397566a1a0f9189dbeb1119a797e35d5985b587596b02f6631d1eacec40252d, downloaded 2026-10-24).
  An expansion of Kenney's Tiny Dungeon, "Made with Kenney's permission".
- License: Creative Commons Zero (CC0 1.0). The `License.txt` in the zip reads:
  "License: (Creative Commons Zero, CC0)" / "http://creativecommons.org/publicdomain/zero/1.0/".
  Full text: `art/creatures/License-Tiny-Creatures.txt` (verbatim copy).
- Used: skeleton (tile_0002), red dragon (tile_0034), wraith (tile_0005), troll (tile_0043), Drowned King = crowned
  undead king (tile_0097), Death Knight = dark knight (tile_0098), Drowned = blue-haired siren (tile_0027), in `art/creatures/`.
  They're cropped from `Tilemap/tilemap_packed.png` because the pack's `Tiles/` PNGs have an opaque black background.
  Pixels are unmodified and untinted. Mapping: `art/creatures/MAPPING.md`.

## 5. Self-generated brand art (dungeon-loadout) - CC0

- `art/brand/` icon (16x16 master plus integer-scaled sizes, favicon, apple-touch, pixel-rect `icon.svg`) and the 800x600
  boot splash. Generated procedurally by `art/brand/make_brand.py` (DL Art, 2026-10-24) from CC0 inputs only:
  Kenney Tiny Dungeon tiles 89, 40, 98 and 104; Tiny Creatures red dragon; Kenney Pixel font.
- Released by the project as CC0 1.0 (self-generated). They replace the default Godot logo icon and splash (CC BY 4.0) once Build integrates them.

## Stand-in mapping (Tiny Dungeon tile numbers; for Design to confirm)

Scale: hero and regular enemies x5 (80px); Young Red Dragon x7 (112px, ~1.5x). Tints are multiplied over the tile.

| Character | Tile | Tint | Note |
|---|---|---|---|
| Hero | 98 adventurer | - | |
| Crypt Rat | 123 rat | - | |
| Skeleton | 121 ghost | bone #E8E2D0 | stand-in: pack has no skeleton |
| Cultist | 111 hooded robe | - | |
| Ghoul (elite) | 108 green ghoul | - | |
| Bone Warden (boss) | 96 armoured knight | bone #E8E2D0 | |
| Drowned | 108 ghoul | blue #7FB4E8 | shares tile with Ghoul |
| Bog Witch | 100 old woman | pale green #B8E0A0 | |
| Gnoll | 112 bandana orc | - | |
| Troll (elite) | 87 horned brute | green #8FD394 | stand-in |
| Drowned King (boss) | 84 wizard | blue #7FB4E8 | stand-in |
| Kobold | 124 grey critter | - | stand-in |
| Golem | 109 cyclops | stone #A9A4C0 | stand-in |
| Wraith | 121 ghost | violet #C3A2F0 | shares tile with Skeleton |
| Death Knight (elite) | 97 visored knight | dark red #B07A80 | |
| Young Red Dragon (boss) | 110 red horned beast | - | stand-in: pack has no dragon |

Icons:
- Weapons: swords 103-107, axes 118/119, maces / cudgel / pick 117, spears / harpoon / glaive 131.
- Armour: light 101, metal 102 (shields; the pack has no body armour).
- Trinkets: potions and vials 113-116, 125-128; coins 90; Crown of Ages 89.
- Talents: Bloodied Edge 105, Strike Bonus 104, Cleave 118, Kill Heal 114, Iron Posture 102, Bulwark 101,
  Steady Stance 56, Thorns 41, Firebolt 130, Max Focus 128, Free Skill 116, Start Focus 129.
- Map nodes: Battle 104, Skill 130, Shop 74, Rest 114; Elite / Boss use the act's own elite / boss sprite.
- Guard pop: 102 at x6. Floor: 49 (dimmed, tiled). Shop: Heal 114, Hone 74, Reinforce 102. Start Run: hero 98.

Thanks to Kenney (www.kenney.nl) and 0x72. Crediting is not required by CC0 but is given here.
