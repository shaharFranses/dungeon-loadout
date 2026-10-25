# Asset license ledger

Rule: only **CC0** (or SIL OFL for fonts) third-party assets, or self-made assets released as CC0.
Each file in the shipped build that isn't code appears here. `CREDITS.md` (repo root) holds the
pack-level provenance (download URLs, sha256, tile mapping). This file is the per-asset ledger and
the planned-asset queue. Keep both in the same PR as the asset change.

Status: v1.1 (DL Art, 2026-10-24), audited against main @ a9750c1, with art/assets-v1 additions.

## Shipped

| Path | Asset | Source | License | License file in repo | Notes |
|---|---|---|---|---|---|
| `art/tile_0041,0049,0056,0074,0084,0087,0089,0090,0096-0098,0100-0119,0121,0123-0131.png` (41 files) | Kenney Tiny Dungeon 1.0 tiles | https://kenney.nl/assets/tiny-dungeon (`kenney_tiny-dungeon.zip`, sha256 c109438ab06f65fd80f9b2686a4cf9c7c11dc64444b47333ec71d602f8bb5fc7) | CC0 1.0 | `art/License-Kenney-Tiny-Dungeon.txt` | Byte-identical to pack `Tiles/` (verified 2026-10-24). Mapping in `CREDITS.md`. |
| `art/fonts/kenney_pixel.ttf` | Kenney Pixel font | https://kenney.nl/assets/kenney-fonts (sha256 in `CREDITS.md`) | CC0 1.0 | `art/fonts/License-Kenney-Fonts.txt` | Global UI font. |
| `icon.svg` → `docs/index.icon.png`, `docs/index.apple-touch-icon.png` | Godot engine logo (project template default) | Godot Engine | **CC BY 4.0** (Andrea Calabró) | none | **Not CC0, so replace it**: the replacement is ready in `art/brand/` (Build to point `config/icon` and the export icons at it). |
| `docs/index.png` | Godot default boot splash (800x600) | Godot export default | Godot logo, CC BY 4.0 | none | **Replace it**: `art/brand/boot_splash_800x600.png` is ready (Build to set `application/boot_splash/image`). |
| `art/creatures/skeleton.png`, `red_dragon.png`, `wraith.png`, `troll.png`, `drowned_king.png`, `death_knight.png`, `drowned.png`, `bog_witch.png`, `golem.png` | Tiny Creatures 1.0 tiles 0002, 0034, 0005, 0043, 0097, 0098, 0027, 0101, 0128 (16x16 RGBA, untinted) | https://opengameart.org/content/tiny-creatures (`tiny-creatures.zip`, sha256 b397566a1a0f9189dbeb1119a797e35d5985b587596b02f6631d1eacec40252d), Clint Bellanger | CC0 1.0. The zip's License.txt says "License: (Creative Commons Zero, CC0)" and gives http://creativecommons.org/publicdomain/zero/1.0/ | `art/creatures/License-Tiny-Creatures.txt` | Cropped from `Tilemap/tilemap_packed.png` (sha256 1fd68a8434e3269bb10a76e50491dc61ac45b1da4ad543c7588970f2c582ca81). Opaque pixels are identical to `Tiles/`. File sha256: skeleton cd053a78…3936, red_dragon f5901672…c23b, wraith aec47d98…791f, troll 64588551…a5ea, drowned_king 7c7b2413…14aa7, death_knight 5d9b25ab…1372, drowned 83237a4e…c56c0, bog_witch c155205c923616c328c1b6583def29d72bedae443f8c4ffe9c97354af729a348, golem 4f705cb8990a674fea782adfa524c86c3ad44d4bcd2b95cb0b901de06cc964f5. In the repo but **not yet wired in** (see `art/creatures/MAPPING.md`). |
| `art/brand/icon_16.png` (master), `icon_32/48/128/144/192/256/512.png`, `apple-touch-icon_180.png`, `favicon.ico`, `icon.svg` | Game icon: Kenney chest (tile 89) re-outlined at 1px `#3F2631` on `#262B44` | **self-generated** by `art/brand/make_brand.py` from CC0 inputs | **CC0 1.0 (self-generated)** | n/a | Sizes are exact nearest-neighbour multiples of the 16x16 master. The 180 is x11 plus 2px padding. `icon.svg` is 16x16 rects with `crispEdges`. Not yet wired in. |
| `art/brand/boot_splash_800x600.png` | Boot splash: "Dungeon Loadout" in Kenney Pixel (16px, 1px outline, x6) plus hero (TD 98, x8), sword (TD 104, x4) and red dragon (Tiny Creatures, flipped, x12) on stone brick (TD 40, x4), with a `#2B2329` background (a5.1: recoloured from `#1B1A24` to the rendered backdrop, Art.BG) | **self-generated** (same script) | **CC0 1.0 (self-generated)** | n/a | Same size and format as `docs/index.png` (800x600 RGBA). sha256 499ae10a…a48. Not yet wired in. |
| `art/brand/make_brand.py` | Generator script | self | CC0 1.0 | n/a | Re-run with the two pack zips unpacked. |
| UI frames, bars, backdrop | Code-drawn (`StyleBoxFlat`, `ColorRect`, `Line2D`) | self (`scripts/art.gd`, `ui_util.gd`, `combat_scene.gd`, `map_links.gd`) | project code | n/a | No external art. |
| Shaders | none | n/a | n/a | n/a | No `.gdshader` files in the repo. |

## Evaluated, not used

| Asset | Source | Why not |
|---|---|---|
| 0x72 16x16 DungeonTileset II v1.7 | https://0x72.itch.io/dungeontileset-ii | The download has no license file (page says CC0). Rejected per rule. See `CREDITS.md` section 3. |

## Planned (candidates, not yet in the repo)

| Priority | For | Candidate | Source | License (as stated in the download) | Status |
|---|---|---|---|---|---|
| alt | Dragon (fallback) | "16x16 dragon" by Chasersgaming (`nes_rpg_dragon.zip`) | https://opengameart.org/content/16x16-dragon | CC0 (page) | NES palette and no Kenney outline means style drift. Fallback only; check the zip for a license file. |
| alt | Skeleton (fallback) | "Treasure hunter game assets" by hdst (`TreasureHunter16x16.zip`) | https://opengameart.org/content/treasure-hunter-game-assets | CC0 (page) | Different outline and palette. Fallback only. |
| P2 | 9-slice UI frames (panel, button states) | self-made 16x16 frames in UI palette | self | CC0 (ours) | to make |
| P2 | Portal cover 630x500 + screenshots | composed from shipped CC0 sprites + self-made logo | self + Kenney / Tiny Creatures | CC0 | to make |
| opt | Title font | Press Start 2P | https://fonts.google.com/specimen/Press+Start+2P | SIL OFL 1.1 | only if Kenney Pixel titles fall short |

When a planned asset ships: copy the pack's license text into the repo next to it (as with Kenney),
move the row to **Shipped**, and add the pack to `CREDITS.md`.
