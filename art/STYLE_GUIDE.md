# dungeon-loadout Art Style Guide

Status: draft v1 (DL Art, 2026-10-24), written against main @ a9750c1 (art passes A to A4).
It applies to every sprite, icon, font, UI frame, and piece of portal art. If code or art
disagrees with this file, fix the code or the art, or change this file in the same PR.

## 1. Direction

- Base set: **Kenney Tiny Dungeon** (CC0), 16x16 tiles, unmodified pixels.
- Gap-filler set: **Tiny Creatures** by Clint Bellanger (CC0, built as a Tiny Dungeon expansion
  with Kenney's permission; same 16x16 grid, thick outline, and palette). Use it for any monster
  Tiny Dungeon lacks (Skeleton, Dragon, and others). See `art/LICENSES.md`.
- Only **CC0** assets, or assets we make ourselves (released as CC0). No CC-BY, no "free for
  personal use", and no pack whose download has no license file. Every file goes in `art/LICENSES.md`.
- Look: chunky, readable, dark dungeon. Sprites carry the colour. UI chrome stays quiet.

## 2. Palettes

There are two palettes, with separate jobs. Don't mix them up.

### 2a. Sprite palette (Kenney Tiny Dungeon, extracted from all 132 tiles)

27 opaque colours, sorted by pixel count. New or edited sprite pixels must use these colours only.

| Hex | Role (approx.) |
|---|---|
| `#3F2631` | outline (the universal dark outline) |
| `#8B9BB4` | steel / stone mid |
| `#EAA56C` | skin / wood light |
| `#C0CBDC` | steel / stone light |
| `#262B44` | deep shadow / dark cloth |
| `#763B36` | wood / leather dark |
| `#52607C` | steel / stone dark |
| `#BD6C4A` | wood / leather mid |
| `#CF8254` | skin shadow |
| `#F7C282` | skin / gold highlight |
| `#FFFFFF` | specular |
| `#43E1B3` | green-teal (potions, ghoul) |
| `#E84537` | red (blood, potions, fire) |
| `#E19A65` | skin mid |
| `#FF706D` | red light |
| `#25956A` | green-teal dark |
| `#9B4CA3` | purple (magic) |
| `#5A6988` | steel / stone dark 2 |
| `#D176D0` | purple light |
| `#0099DB` | blue (water, mana) |
| `#69FFD4` | green-teal light |
| `#75E3FF` | blue light |
| `#E4EDF9` | white-steel |
| `#FEAE34` | gold / fire |
| `#FEC99C` | skin highlight |
| `#FEE761` | gold light |
| `#AAB7CC` | steel / stone light 2 |

Source swatch: `kenney_tiny-dungeon.zip` (sha256 c109438a...5fc7), extracted to `palette.png` / `palette.txt`.
Tiny Creatures shares 22 of its 23 colours with this list.

### 2b. UI palette (the 10 colours from LOOP_SPEC section 7, which is the canonical list)

| Token | Hex | Use |
|---|---|---|
| `BG` | `#1B1A24` | background, deep stone; also the combat strip |
| `PANEL` | `#2E2C3B` | panels, button fill |
| `EDGE` | `#5A5670` | panel edge, dim text, disabled, inactive map links |
| `BONE` | `#E8E2D0` | main text, Common rarity, Battle node |
| `GOLD` | `#E3B341` | gold, currency, Legendary, Shop node, pressed/focus |
| `RED` | `#C8433A` | HP, damage, Enrage, Elite/Boss nodes |
| `BLUE` | `#4A8FD8` | Block / Guard |
| `PURPLE` | `#9B5DE5` | Focus / Arcane, Skill node, Hex |
| `GREEN` | `#5DBB63` | heal, Uncommon, Rest node |
| `RARE` | `#3FA7D6` | Rare rarity |

Rules:
1. Code uses these through **one source**: the constants in `scripts/art.gd` (`Art.BG`, `Art.PANEL`, ...).
   Other scripts reference `Art.*` and don't re-declare hex values. Today they are duplicated in
   `ui_util.gd`, `combat_scene.gd` (`C_*`), `map_scene.gd`, `gear_data.gd`, `combat_state.gd`, and as
   floats in `.tscn` files.
2. Allowed derived values: alpha variants of a token (e.g. `RED` at 0.85 for a gradient), and
   `lightened()` / `darkened()` of at most 0.3 for hover, pressed, or disabled states.
3. **Hit flashes** may use a modulate above 1.0 (`Color(2,2,2)` and the like) for at most 0.25 s. They are not palette colours.
4. **Sprite tints** (the multiply tints on shared tiles) must be listed in section 2c. Prefer a real
   sprite over a tint: each tint is debt.
5. Text colour on `PANEL` or `BG` must be one of the 10 tokens. Contrast check: `EDGE` on `PANEL`
   is about 2:1, so use it only for disabled or decorative text. Never use it for text the player must read.

### 2c. Sanctioned sprite tints (temporary, until real sprites land)

`#7FB4E8` drowned blue · `#B8E0A0` bog green · `#8FD394` troll green · `#A9A4C0` stone ·
`#C3A2F0` wraith violet · `#B07A80` death-knight red. `#E8E2D0` (BONE) is on palette.

### 2d. Off-palette colours found in main @ a9750c1 (to fix)

| Where | Value | Fix |
|---|---|---|
| `scenes/boot.tscn:21`, `scenes/result.tscn:21` | `Color(0.1,0.1,0.15)` = `#1A1A26` | `Art.BG` |
| `scenes/combat.tscn:21` | `Color(0.12,0.1,0.14)` = `#1F1A24` | `Art.BG` |
| `scenes/map.tscn:22` | `#1B1A24` as floats | OK value; reference `Art.BG` |
| `scenes/map.tscn:49,60` | RED / GOLD as floats | OK values; reference tokens |
| `scripts/result_scene.gd:33` | `Color(0.1,0.15,0.1)` win screen (green) | `Art.BG` plus backdrop; show the win with a GOLD title |
| `scripts/result_scene.gd:37` | `Color(0.15,0.1,0.1)` loss screen | `Art.BG` plus backdrop; show the loss with a RED title |
| `scripts/combat_scene.gd:159` | `Color(0.12,0.1,0.12)` bar back | `Art.BG` |
| `scripts/combat_scene.gd:163` | `Color(0.95,0.75,0.7)` HP ghost bar | `BONE` or `RED.lightened(0.3)` |
| `scripts/combat_scene.gd:344,492` | `Color(1,0.25,0.25)` / `(1,0.3,0.3)` Enrage text | `Art.RED` (lighten 0.2 if contrast needs it) |
| `scripts/combat_scene.gd:547` | `Color(0.05,0.04,0.08)` popup outline | sprite outline `#3F2631` or `Art.BG` |
| `scripts/art.gd:159` | floor modulate `Color(0.42,0.40,0.55,0.22)` | OK as a dim, but document it as `FLOOR_DIM` |

## 3. Grid and scale

- Base unit: **16x16 px**. Every sprite or icon is authored at 16x16 (bosses can be 32x32, still pixel art at 1x).
- **Integer scale only.** A sprite is drawn at N x 16 px with N a whole number. No fractional scale and
  no rotation except 90-degree steps. Today's factors: hero and regular enemies x5 (80 px), boss
  x7 (112 px), map and item icons x2 (32 px), backdrop floor x4; portrait gives x8 and x12.
- Use the fewest scales per screen. Target set: **x2 icons in text/buttons, x3 icons on cards,
  x5 actors, x7 bosses** (landscape). Don't put x2 and x4 icons side by side on one screen.
- Position on whole pixels. Sprites should land on integer canvas coordinates (`position.round()`);
  never centre with a /2 that leaves .5.
- Caveat: with `stretch_mode=canvas_items` + `aspect=expand`, the canvas is scaled again by window/1280.
  At non-integer window scales (e.g. a 390x844 phone has a factor of about 0.54), texels become
  uneven. Accepted trade-off for the web; don't add any further non-integer scaling on top of it.

## 4. Outline and shading

- Every actor and icon has the Kenney **1 px dark outline in `#3F2631`** (included in the source tiles).
  Self-made sprites must match it: 1 px at 1x, outside the silhouette, no anti-aliasing.
- Light comes from the top-left. Use 2 to 3 tones per material, taken from palette 2a. No gradients, no dithering noise.
- Glows and shadows behind sprites (the current soft halo) must be pixel shapes in palette colours,
  not blurred. Avoid Godot glow, blur, or smooth shaders on pixel art.

## 5. Font

- UI font: **Kenney Pixel** (CC0, from Kenney Fonts). It's already shipped as `art/fonts/kenney_pixel.ttf`.
  Alternatives if more glyphs or weights are needed: Kenney Mini / Kenney Mini Square (CC0), or
  **Press Start 2P** (SIL OFL 1.1, Google Fonts) for big titles only. CC0 or OFL only. Don't use
  fonts with custom "free to use" terms.
- Render settings: antialiasing **off**, hinting **none**, subpixel positioning **off**, no mipmaps,
  no MSDF. Sizes go through `Art.fs()` and land on multiples of 8 (the font's 8 px design height
  at whole multiples). Keep the widened space (`SPACING_SPACE = 6`).
- Minimum on-screen size: **16 px cap height on desktop at 1280x720** and **>= 12 CSS px on a 390x844 phone**.
  Body copy at `fs(14)` currently renders at about 7 CSS px on phones, which is too small (see the audit).
- Max three text sizes per screen: title, body, small. Small is only for secondary stats.

## 6. UI frames and 9-slice

- Current state: frames are `StyleBoxFlat` (PANEL fill, EDGE 2 px border, 2 px corner radius).
  That's acceptable, but the corner radius smooths edges at non-integer scale. **Set the radius to 0** for a pixel look.
- Target: a 16x16 **9-slice frame sprite** (self-made or from Kenney, CC0) drawn in UI palette tokens, used via
  `StyleBoxTexture` with `texture_margin_* = 4` (a 4 px corner at 1x), `axis_stretch = TILE` (or `TILE_FIT`),
  and the texture filter nearest. One frame each for panel, button-normal, button-hover, button-pressed,
  and button-disabled (they differ only in edge colour: EDGE / BONE-dark / GOLD / EDGE-dark).
- Border thickness: one art pixel at the frame's scale (2 px at x2). All frames on a screen use the same scale.
- Content margin: 10 px horizontal, 6 px vertical at 1280x720 (as now).
- **Tap targets: >= 44x44 CSS px** at the actual device size. On desktop 1280x720 that's >= 44 canvas
  px. On a 390x844 phone (canvas 720x1558, factor about 0.54) it's **>= 82 canvas px tall**. Every button,
  map node, and toggle counts, including "Speed 1x".
- Disabled state: EDGE text on a darkened PANEL, plus a lock or "x" glyph. Don't rely on contrast alone.

## 7. Godot import and render settings (pixel art)

Project (`project.godot`):
- `rendering/textures/canvas_textures/default_texture_filter = 0` (Nearest). Set it, and leave it.
- No per-node filter overrides to Linear on pixel art.
- Renderer: GL Compatibility (web). No 2D glow, no MSAA on canvas.
- Optional later: `rendering/2d/snap/snap_2d_transforms_to_pixel = true` and
  `snap_2d_vertices_to_pixel = true` to stop sub-pixel shimmer during tweens.

Per texture (`*.png.import`); already correct on all 41 tiles:
- `compress/mode = 0` (**Lossless**). Never VRAM-compressed (ETC2/S3TC smears palettes) and never Lossy.
- `mipmaps/generate = false`.
- `process/fix_alpha_border = true`, `process/premult_alpha = false`.
- `process/size_limit = 0`, no "detect 3D".

Fonts (`*.ttf.import`): set `antialiasing = 0` (None), `hinting = 0`, `subpixel_positioning = 0`,
`generate_mipmaps = false`, `multichannel_signed_distance_field = false` in the import file too.
They are currently forced at runtime in `Art.make_theme()`; setting them in the import as well makes
the editor preview match.

Runtime scaling: `Art.tex()` upscales by `Image.INTERPOLATE_NEAREST` to an integer factor. Keep it that way. Don't
use `TextureRect.STRETCH_SCALE` with non-integer rects on pixel textures.

## 8. Naming and files

- Shipped source tiles keep their pack names: `art/tile_NNNN.png` = Kenney Tiny Dungeon.
  New packs go in a subfolder: `art/tiny-creatures/tile_NNNN.png`, `art/ui/frame_panel.png`, `art/portal/...`.
- Self-made art: `art/self/<name>.png` with a line in `art/LICENSES.md` ("self-made, CC0, author, date").
- Never edit pack pixels in place. A modified tile becomes a self-made derivative in `art/self/` and
  is logged with its source.

## 9. Portal art (itch.io / web portals), not started yet

- Icon: 512x512 and 144/180 PWA sizes, from a 32x32 (or 16x16) self-made pixel icon scaled by an integer factor
  (x16 / x32), palette-only, on `BG`. It replaces the default Godot `icon.svg` (the Godot logo is CC BY 4.0, not CC0).
- Boot splash: replace the default Godot splash (`docs/index.png` 800x600) with a BG-coloured splash, logo at integer scale.
- Cover: 630x500 (itch) composed from in-game sprites at x8 to x10 plus a logo; there's an 8 px safe margin.
- Screenshots: 1280x720 and 390x844 straight from the build (the `/workspace/dl-art/audit` method), with no UI mock-ups.
