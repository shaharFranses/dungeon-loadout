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

### 2b. UI palette (LOOP_SPEC section 7 + a5.1: BG moved to #2B2329, old BG kept as BG_DEEP)

| Token | Hex | Use |
|---|---|---|
| `BG` | `#2B2329` | backdrop: what the base plus tinted floor actually renders (since a5.1) |
| `BG_DEEP` | `#1B1A24` | darker accents on the backdrop: HP bar trough, turn banner strip, pressed buttons, popup shadow, label plates |
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
5. Text colour must be one of the text roles in section 10. Contrast check: `EDGE` on `PANEL`
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
- Sizes, outline, plates and colours: see **section 10 (Typography)**.
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

## 10. Typography (art-a6 spec; measured on main a668035, 2026-10-25)

Font: Kenney Pixel. Native size is **16** (1 font pixel = 1 px at `font_size` 16, cap height 7 px).
**s = font_size / 16 must be a whole number.** Allowed sizes: 16, 32, 48, 64, 80, 96. The current 24, 40, 56 and 80-on-phone
are 1.5x, 2.5x and 3.5x, which gives uneven or blended glyph pixels (measured blend pixels such as `#B3ADA2` around BONE text).
Keep `antialiasing = NONE`, `hinting = NONE` and `subpixel_positioning = DISABLED`. In `Art.fs()`, replace the x1.6/x2.0 multiply and the snap to 8 with the tier table below.

### Sizes (canvas px; phone = 720x1558 canvas at 390x844, k = 0.5417 CSS px per canvas px)

Revised 2026-10-25 (Studio Manager: phone body 64). The phone column was tested headless on art-a6 6a51e43 with the TIER table
patched (captures in DL Art's `/workspace/dl-art/audit-a6-64/`). Title 128 / heading 96 wrapped "Choose a Talent",
"Blacksmith + Shop", "Enter the Crypt" and "Dragon's Vault Cleared" onto 2 lines, so the phone title is 96 and the heading 80.

| Tier | Desktop 1280x720 | Phone canvas → CSS font px / cap px |
|---|---|---|
| Title | 64 (4x) | 96 (6x) → 52.0 / 22.8 |
| Heading (screen subtitles, card names, "Enemies"/"Hero", gold reward line) | 48 (3x) | 80 (5x) → 43.3 / 19.0 |
| Body (buttons, stats, descriptions, combat HUD, enemy names, intents, action buttons, map nodes) | 32 (2x) | **64 (4x) → 34.7 / 15.2** |
| Small (secondary lines) | 32 (2x), dim colour | 64 (4x) → 34.7 / 15.2 |
| Number pop-ups | 48 (3x); crit/boss 64 | 96 (6x); crit/boss 128 (8x) |

Godot: `Art.TIER = {"title": [64, 96], "heading": [48, 80], "body": [32, 64], "small": [32, 64], "popup": [48, 96], "crit": [64, 128]}`.
Phone floor: **64 canvas = 34.7 CSS px**. Nothing on phone goes below 64, including the combat HUD line, enemy names, intents,
action buttons and Speed. Never use 16 for UI text.

Phone layout rules at body 64 (about 22 characters per 680 px line):
- Labels: `autowrap_mode = AUTOWRAP_WORD_SMART` on every description or status label. Two or three lines are allowed.
- Stat lines ("HP / Gold / Strike / Guard") must never break inside a pair. Use a `HFlowContainer` of one Label per pair, or join with U+00A0.
- Buttons: `autowrap_mode = AUTOWRAP_WORD_SMART` (4.3 Button supports it). Use explicit 2-line text where the break position matters.
- Screens taller than the canvas (shop) go in a `ScrollContainer`, or reduce VBox `separation` on phone.

### Outline and shadow per tier (Godot 4.3, measured)

In 4.3, outline thickness ≈ `outline_size / 4` px per side: at font 32, `outline_size` 2 or 4 gives 1 px and 8 gives 2 px,
with rounded corners. A shadow with `shadow_size = 0` is a crisp pixel copy, so use it for the pixel look.

| Tier | Outline | Shadow |
|---|---|---|
| Title, Heading | none | `BG_DEEP #1B1A24`, alpha 1, offset `(s, s)` (desktop 4/3 px, phone 6/5 px), `shadow_size` 0 |
| Body, Small on BG/PANEL/plate | none | none |
| Text directly over sprites or floor (only if a plate can't be used) | `BG_DEEP #1B1A24`, `outline_size = 4*s` | `BG_DEEP`, offset `(s, s)`, size 0 |
| Number pop-ups | `BG_DEEP #1B1A24`, `outline_size = 4*s` (desktop 48 → 12, phone 96 → 24, crit 128 → 32) | `BG_DEEP`, offset `(s, s)`, size 0 |

Don't use `OUTLINE #3F2631` for text outlines. It's 1.11:1 against BG, so it disappears on the backdrop.

### Label plate (any static text that overlaps sprites, floor or map lines)

`StyleBoxFlat`: `bg_color = Color("#1B1A24", 0.92)`, `border_width_* = s` (2 on desktop body, 4 on phone body),
`border_color = Color("#3F2631")`, `corner_radius_* = 0`, `anti_aliasing = false`,
`content_margin_left/right = 3*s` (6 / 12; phone map nodes may drop to 2*s = 8), `content_margin_top/bottom = s` (2 / 4).
Worst case over a pure-white sprite pixel, the plate renders as `#2D2C36` (all text roles below pass on it).

### Text colours (contrast vs BG #2B2329 / BG_DEEP #1B1A24 / PANEL #2E2C3B / plate-worst #2D2C36)

| Role | Colour | BG | DEEP | PANEL | Plate |
|---|---|---|---|---|---|
| Primary | `BONE #E8E2D0` | 11.80 | 13.30 | 10.54 | 10.64 |
| Dim / secondary (replaces EDGE text) | `#AAB7CC` (Kenney steel light) | 7.53 | 8.49 | 6.73 | 6.79 |
| Disabled (plus a lock or "x" glyph) | `#8B9BB4` (Kenney steel) | 5.41 | 6.10 | 4.84 | 4.88 |
| Positive / heal / Uncommon | `GREEN #5DBB63` | 6.37 | 7.18 | 5.69 | 5.74 |
| Negative / damage / Enrage | `#FF706D` (Kenney red light) | 5.67 | 6.39 | 5.06 | 5.11 |
| Gold / Legendary | `GOLD #E3B341` | 7.85 | 8.85 | 7.01 | 7.08 |
| Block (text) | `#75E3FF` (Kenney cyan light) | 10.32 | 11.63 | 9.22 | 9.30 |
| Focus / Arcane (text) | `#D176D0` (Kenney purple light) | 5.25 | 5.91 | 4.69 | 4.73 |
| Rare | `RARE #3FA7D6` | 5.61 | 6.32 | 5.01 | 4.71* |

*Rare on the plate is 4.71 (passes). `RED #C8433A` (3.14), `RED_TEXT` (4.33), `PURPLE #9B5DE5` (3.70), `BLUE #4A8FD8` (4.03 on PANEL) and
`EDGE #5A5670` (2.18) are **fill and bar colours only, not text**. Don't dim text with `modulate`. Use the Dim or Disabled role instead
(map locked nodes currently render `#341F4D` / `#441613` on `#1A1921` = 1.20 / 1.14:1).

Minimum contrast: body and small **4.5:1**. Title, heading and pop-ups (≥ 48 desktop / 80 phone) **3:1**. Every role above meets 4.5 on every surface.

### Godot property names

- Label: `label_settings = LabelSettings` with `font`, `font_size`, `font_color`, `outline_size`, `outline_color`,
  `shadow_size` (0), `shadow_color`, `shadow_offset` (Vector2).
- Theme or overrides (Label/Button): `theme_override_font_sizes/font_size`, `theme_override_colors/font_color`,
  `theme_override_colors/font_outline_color`, `theme_override_constants/outline_size`,
  `theme_override_colors/font_shadow_color`, `theme_override_constants/shadow_offset_x`, `theme_override_constants/shadow_offset_y`,
  `theme_override_constants/shadow_outline_size` (0). Button: `font_disabled_color` = `#8B9BB4`.
- Plate: a `PanelContainer` with `theme_override_styles/panel = StyleBoxFlat` (values above) wrapping the Label.
