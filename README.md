# Godot Simple Bitmap Font Importer

This is a simple import plugin for **Godot 4.x** that allows you to import a fixed-tile bitmap font from a PNG file.

---

## Usage

1. Install the plugin:
   - Copy the `addons/godot_simple_bitmap_font/` folder into your project
   - Enable the plugin in **Project > Project Settings > Plugins**

2. Prepare your PNG:
   - Fixed-size grid (e.g. 8×8 pixel tiles)
   - Characters start at Unicode 0 and go row-by-row

3. Import your PNG:
   - Select the `.png` file
   - In the **Import tab**, change the importer to:
     > `Godot Simple Bitmap Font`
   - Adjust settings and click **Reimport**

---

## Import parameters

| Setting             | Description                          |
|---------------------|--------------------------------------|
| `tile_width`        | Width of each glyph tile             |
| `tile_height`       | Height of each glyph tile            |
| `letter_spacing`    | Extra spacing added after each glyph |
| `glyphs`            | Total number of glyphs to create     |
| `spacing_overrides` | Per-character spacing & offset       |

Use the `spacing_overrides` field to control offset and spacing for specific characters.

```
/\<char\_or\_range>/<offset>,<spacing>

Examples:

/./0,2
/a-c/1,4
/%fs%/0,1
```