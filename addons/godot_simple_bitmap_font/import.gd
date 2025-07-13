@tool
extends EditorImportPlugin

func _get_importer_name() -> String:
    return "dt.godot_simple_bitmap_font"

func _get_visible_name() -> String:
    return "Godot Simple Bitmap Font"

func _get_recognized_extensions() -> PackedStringArray:
    return ["png"]

func _get_save_extension() -> String:
    return "fontdata"

func _get_resource_type() -> String:
    return "FontFile"

func _get_option_visibility(path: String, option: StringName, options: Dictionary) -> bool:
    return true

func _get_preset_count() -> int:
    return 1

func _get_preset_name(preset: int) -> String:
    return "Default"

func _get_import_options(path, preset) -> Array[Dictionary]:
    return [
        { 
            name = "tile_width", 
            default_value = 8, 
            #usage = "The tile width.",
        }, { 
            name = "tile_height", 
            default_value = 8, 
            #usage = "The tile height.",
        }, { 
            name = "letter_spacing", 
            default_value = 0, 
            #usage = "The default letter spacing (+ tile width).",
        }, { 
            name = "glyphs",
            default_value = 127,
            property_hint = PROPERTY_HINT_RANGE,
            hint_string = "0,255,1",
            #usage = "The number of glyphs to create.",
        }, {
            name = "spacing_overrides",
            default_value = "",
            property_hint = PROPERTY_HINT_MULTILINE_TEXT,
            #usage = "Format: /char_or_range/offset,spacing (e.g. /./0,2/a-c/1,4). Use %fs% for forward slash.",
        },
    ]

func _get_priority() -> float:
    return 1.0

func _get_import_order() -> int:
    return 0

func _parse_overrides(overrides_string: String) -> Dictionary:
    var spacing_overrides: Dictionary = {}
    var offset_overrides: Dictionary = {}

    var parts: PackedStringArray = overrides_string.strip_edges().split("/", false)
    for i in range(0, parts.size(), 2):
        if i + 1 >= parts.size():
            push_warning("Malformed override entry near '%s'" % parts[i])
            break

        var part: String = parts[i]
        var values: PackedStringArray = parts[i + 1].split(",", false)
        if values.size() != 2:
            push_warning("Invalid override values for '%s'" % part)
            continue

        var offset: int = int(values[0])
        var spacing: int = int(values[1])

        if part.length() == 1 or part == "%fs%":
            var c: String = "/" if part == "%fs%" else part
            if spacing_overrides.has(c) or offset_overrides.has(c):
                push_warning("Duplicate override for character '%s'" % c)
            offset_overrides[c] = offset
            spacing_overrides[c] = spacing
        elif part.length() == 3 and part[1] == "-":
            var start: int = part.unicode_at(0)
            var end: int = part.unicode_at(2)
            if start > end:
                push_warning("Invalid character range: '%s'" % part)
                continue
            for code in range(start, end + 1):
                var c: String = String.chr(code)
                if spacing_overrides.has(c) or offset_overrides.has(c):
                    push_warning("Duplicate override for character '%s'" % c)
                offset_overrides[c] = offset
                spacing_overrides[c] = spacing
        else:
            push_warning("Invalid glyph specifier: '%s'" % part)

    return {
        "offsets": offset_overrides,
        "spacings": spacing_overrides,
    }

func _import(source_file, save_path, options, _platform_variants, _gen_files) -> Error:
    var file: FileAccess = FileAccess.open(source_file, FileAccess.READ)
    if file == null:
        push_error("Could not open source PNG file.")
        return ERR_FILE_NOT_FOUND

    var image: Image = Image.new()
    var error: int = image.load_png_from_buffer(file.get_buffer(file.get_length()))
    file.close()

    if error != OK:
        push_error("Could not decode PNG image.")
        return error

    var tile_w: int = options.tile_width
    var tile_h: int = options.tile_height
    var spacing: int = options.letter_spacing
    var glyphs: int = options.glyphs

    var tiles_x: int = image.get_width() / tile_w
    var tiles_y: int = image.get_height() / tile_h
    var tile_count: int = tiles_x * tiles_y

    if glyphs > tile_count:
        push_warning("Image does not have enough tiles for %d glyphs. Truncating." % glyphs)
        glyphs = tile_count

    var overrides: Dictionary = _parse_overrides(options.spacing_overrides)

    var font: FontFile = FontFile.new()
    var size: Vector2i = Vector2i(tile_h, 0)
    font.set_texture_image(0, size, 0, image)
    font.fixed_size = tile_h
    font.allow_system_fallback = false
    font.set_cache_descent(0, size.x, tile_h)

    for i in range(glyphs):
        var tx: int = i % tiles_x
        var ty: int = i / tiles_x
        var x: int = tx * tile_w
        var y: int = ty * tile_h
        var rect: Rect2i = Rect2i(x, y, tile_w, tile_h)
        var c: String = String.chr(i)
        var char_spacing: int = overrides.spacings.get(c, spacing)
        var offset: int = overrides.offsets.get(c, 0)
        var advance: int = tile_w + char_spacing

        font.set_glyph_uv_rect(0, size, i, rect)
        font.set_glyph_advance(0, size.x, i, Vector2i(advance, 0))
        font.set_glyph_texture_idx(0, size, i, 0)
        font.set_glyph_offset(0, size, i, Vector2i(offset, 0))
        font.set_glyph_size(0, size, i, rect.size)

    return ResourceSaver.save(font, "%s.%s" % [save_path, _get_save_extension()])
