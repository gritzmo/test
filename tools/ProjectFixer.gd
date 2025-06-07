@tool
extends EditorPlugin

"""
ProjectFixer
=============
WHY:
    Some scripts in the repository contain syntax mistakes or duplicate
    class_name declarations. Many scripts also lack a matching scene.
    This tool scans every .gd file, flags parser errors, performs a few
    safe AUTO-FIX actions and generates stub scenes so the project can
    run in the editor.

HOW:
    - Iterates all scripts under res://
    - Uses GDScriptLanguage to parse each script and report problems
    - Writes FIX-ME comments to scripts when issues are found
    - Optionally removes duplicate class_name lines and comments stray
      tokens
    - Creates simple scene stubs for scripts that have none
    - Adds a menu entry under Tools so it can be run from the editor
"""

const MENU_TEXT := "Run Project Fixer"
const STUB_DIR := "res://generated_scenes/"
const INDEX_FILE := STUB_DIR + "README.txt"

var errors_flagged := 0
var scenes_generated := 0
var new_scene_paths: Array[String] = []
var class_name_map: Dictionary = {}

func _enter_tree() -> void:
    # Expose the tool in the editor's top menu.
    add_tool_menu_item(MENU_TEXT, callable(self, "_run_fixer"))

func _exit_tree() -> void:
    # Clean up menu item when the plugin is disabled.
    remove_tool_menu_item(MENU_TEXT)

func _run_fixer() -> void:
    errors_flagged = 0
    scenes_generated = 0
    new_scene_paths.clear()
    class_name_map.clear()
    _ensure_stub_dir()

    var scripts := _get_scripts("res://")
    for path in scripts:
        _audit_and_fix_script(path)
    for path in scripts:
        _ensure_scene_for_script(path)
    _update_index()

    print_rich("[color=green]\u2705 ProjectFixer finished. %d errors flagged, %d scenes generated.[/color]" % [errors_flagged, scenes_generated])

func _ensure_stub_dir() -> void:
    if not DirAccess.dir_exists_absolute(STUB_DIR):
        DirAccess.make_dir_recursive_absolute(STUB_DIR)

func _get_scripts(base_path: String) -> Array[String]:
    var result: Array[String] = []
    var dir := DirAccess.open(base_path)
    if dir == null:
        return result
    dir.list_dir_begin(true, true)
    var file := dir.get_next()
    while file != "":
        var full_path := base_path.path_join(file)
        if dir.current_is_dir():
            result += _get_scripts(full_path)
        elif file.ends_with(".gd"):
            result.append(full_path)
        file = dir.get_next()
    dir.list_dir_end()
    return result

func _audit_and_fix_script(path: String) -> void:
    var changed := false
    var file := FileAccess.open(path, FileAccess.READ)
    if file == null:
        return
    var lines := file.get_as_text().split("\n")
    file.close()

    var base_file := path.get_file()
    var script_name := base_file.get_basename()

    var class_line_idx := -1
    var class_name := ""
    for i in range(lines.size()):
        var t := lines[i].strip_edges()
        if t.begins_with("class_name "):
            class_line_idx = i
            class_name = t.get_slice(" ", 1).strip_edges()
            break

    if class_name != "":
        if class_name_map.has(class_name):
            errors_flagged += 1
            print_rich("[color=yellow]Duplicate class_name '%s' found in %s[/color]" % [class_name, path])
            _prepend_fixme(lines, "Duplicate class_name '%s'" % class_name)
            if class_name == script_name:
                lines[class_line_idx] = "# AUTO-FIX: removed duplicate class_name"
                changed = true
        else:
            class_name_map[class_name] = path

    var lang := GDScriptLanguage.get_singleton()
    var parse_err := lang.parse(path)
    if parse_err != OK:
        errors_flagged += 1
        var msg := "Parse error"
        if lang.has_method("get_error_text"):
            msg = lang.get_error_text()
        print_rich("[color=yellow]%s: %s[/color]" % [path, msg])
        _prepend_fixme(lines, msg)
        lines = _strip_stray_identifiers(lines)
        changed = true

    if changed:
        var out := String("\n").join(lines)
        file = FileAccess.open(path, FileAccess.WRITE)
        file.store_string(out)
        file.close()

func _prepend_fixme(lines: Array, msg: String) -> void:
    var fixme := "# FIX-ME (ProjectFixer): " + msg
    if lines.size() == 0:
        lines.append(fixme)
        return
    if not lines[0].begins_with("# FIX-ME (ProjectFixer):"):
        lines.insert(0, fixme)
    else:
        lines[0] += " | " + msg

func _strip_stray_identifiers(lines: Array) -> Array:
    var allowed := ["#", "extends", "class_name", "const", "var ", "func ", "static func", "signal", "enum", "@"]
    for i in range(lines.size()):
        var t := lines[i].strip_edges()
        if t == "":
            continue
        var ok := false
        for prefix in allowed:
            if t.begins_with(prefix):
                ok = true
                break
        if not ok:
            lines[i] = "# AUTO-FIX: stray token\n# " + lines[i]
    return lines

func _ensure_scene_for_script(script_path: String) -> void:
    var script_name := script_path.get_file().get_basename()
    var scene_path := STUB_DIR + script_name + ".tscn"
    if ResourceLoader.exists(scene_path):
        return

    var base_class := "Node"
    var text := FileAccess.get_file_as_string(script_path)
    for line in text.split("\n"):
        var trim := line.strip_edges()
        if trim.begins_with("extends"):
            base_class = trim.get_slice(" ", 1).strip_edges()
            if base_class == "":
                base_class = "Node"
            break

    var root := ClassDB.instantiate(base_class)
    if root == null:
        root = Node.new()
    var script_resource := load(script_path)
    root.set_script(script_resource)
    var scene := PackedScene.new()
    scene.pack(root)

    var err := ResourceSaver.save(scene_path, scene)
    if err == OK:
        scenes_generated += 1
        new_scene_paths.append(scene_path)

func _update_index() -> void:
    var lines := []
    if FileAccess.file_exists(INDEX_FILE):
        var f := FileAccess.open(INDEX_FILE, FileAccess.READ)
        lines = f.get_as_text().split("\n")
        f.close()
    for p in new_scene_paths:
        if p not in lines:
            lines.append(p)
    var out := "Stub scenes generated by ProjectFixer.\nReplace them with real scenes when ready.\n\n"
    for l in lines:
        if l.strip_edges() != "":
            out += l + "\n"
    var f2 := FileAccess.open(INDEX_FILE, FileAccess.WRITE)
    f2.store_string(out)
    f2.close()
