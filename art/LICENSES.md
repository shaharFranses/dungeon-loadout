# Asset license ledger

Rule: only **CC0** (or SIL OFL for fonts) third-party assets, or self-made assets released as CC0.
Each file in the shipped build that isn't code appears here. `CREDITS.md` (repo root) holds the
pack-level provenance (download URLs, sha256, tile mapping). This file is the per-asset ledger and
the planned-asset queue. Keep both in the same PR as the asset change.

Status: draft v1 (DL Art, 2026-10-24), audited against main @ a9750c1.

## Shipped

| Path | Asset | Source | License | License file in repo | Notes |
|---|---|---|---|---|---|
| `art/tile_0041,0049,0056,0074,0084,0087,0089,0090,0096-0098,0100-0119,0121,0123-0131.png` (41 files) | Kenney Tiny Dungeon 1.0 tiles | https://kenney.nl/assets/tiny-dungeon (`kenney_tiny-dungeon.zip`, sha256 c109438ab06f65fd80f9b2686a4cf9c7c11dc64444b47333ec71d602f8bb5fc7) | CC0 1.0 | `art/License-Kenney-Tiny-Dungeon.txt` | Byte-identical to pack `Tiles/` (verified 2026-10-24). Mapping in `CREDITS.md`. |
| `art/fonts/kenney_pixel.ttf` | Kenney Pixel font | https://kenney.nl/assets/kenney-fonts (sha256 in `CREDITS.md`) | CC0 1.0 | `art/fonts/License-Kenney-Fonts.txt` | Global UI font. |
| `icon.svg` → `docs/index.icon.png`, `docs/index.apple-touch-icon.png` | Godot engine logo (project template default) | Godot Engine | **CC BY 4.0** (Andrea Calabró) | none | **Not CC0, so replace it** with a self-made icon (see Planned P1). |
| `docs/index.png` | Godot default boot splash (800x600) | Godot export default | Godot logo, CC BY 4.0 | none | **Replace** with a self-made splash (Planned P1). |
| UI frames, bars, backdrop | Code-drawn (`StyleBoxFlat`, `ColorRect`, `Line2D`) | self (`scripts/art.gd`, `ui_util.gd`, `combat_scene.gd`, `map_links.gd`) | project code | n/a | No external art. |
| Shaders | none | n/a | n/a | n/a | No `.gdshader` files in the repo. |

## Evaluated, not used

| Asset | Source | Why not |
|---|---|---|
| 0x72 16x16 DungeonTileset II v1.7 | https://0x72.itch.io/dungeontileset-ii | The download has no license file (page says CC0). Rejected per rule. See `CREDITS.md` section 3. |

## Planned (candidates, not yet in the repo)

| Priority | For | Candidate | Source | License (as stated in the download) | Status |
|---|---|---|---|---|---|
| P0 | Skeleton (replaces ghost 121 + bone tint) | Tiny Creatures `Tiles/tile_0002.png` (skeleton) | https://opengameart.org/content/tiny-creatures (`tiny-creatures.zip`, sha256 b397566a1a0f9189dbeb1119a797e35d5985b587596b02f6631d1eacec40252d) by Clint Bellanger | **CC0 1.0**: `License.txt` in the zip says CC0 | Downloaded to the box for review; Design to confirm. Same 16x16 grid and outline as Tiny Dungeon; 22/23 colours shared. |
| P0 | Young Red Dragon (replaces red beast 110) | Tiny Creatures `Tiles/tile_0034.png` (red dragon) | same zip | CC0 1.0 | as above |
| P1 | Wraith (replaces tinted ghost 121) | Tiny Creatures `Tiles/tile_0005.png` (hooded wraith) | same zip | CC0 1.0 | candidate |
| P1 | Troll (replaces tinted brute 87) | Tiny Creatures `Tiles/tile_0043.png` (green troll) | same zip | CC0 1.0 | candidate |
| P2 | Kobold, Golem, Drowned King, Death Knight, Drowned, Bog Witch (all tinted stand-ins) | Tiny Creatures has kobold, stone/clay/iron golem, lich, death knight, zombie, witch | same zip | CC0 1.0 | DL Art to pick exact tiles from the index sheet |
| alt | Dragon (fallback) | "16x16 dragon" by Chasersgaming (`nes_rpg_dragon.zip`) | https://opengameart.org/content/16x16-dragon | CC0 (page) | NES palette and no Kenney outline means style drift. Fallback only; check the zip for a license file. |
| alt | Skeleton (fallback) | "Treasure hunter game assets" by hdst (`TreasureHunter16x16.zip`) | https://opengameart.org/content/treasure-hunter-game-assets | CC0 (page) | Different outline and palette. Fallback only. |
| P1 | Game icon (512/180/144 + favicon) | self-made 32x32 pixel icon (hero + sword on BG) | self | CC0 (ours) | to make |
| P1 | Boot splash | self-made, BG + logo | self | CC0 (ours) | to make |
| P2 | 9-slice UI frames (panel, button states) | self-made 16x16 frames in UI palette | self | CC0 (ours) | to make |
| P2 | Portal cover 630x500 + screenshots | composed from shipped CC0 sprites + self-made logo | self + Kenney / Tiny Creatures | CC0 | to make |
| opt | Title font | Press Start 2P | https://fonts.google.com/specimen/Press+Start+2P | SIL OFL 1.1 | only if Kenney Pixel titles fall short |

When a planned asset ships: copy the pack's license text into the repo next to it (as with Kenney),
move the row to **Shipped**, and add the pack to `CREDITS.md`.
