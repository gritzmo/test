extends Node
class_name BattleSaveManager

"""Handles saving and loading the current battle state."""

const SAVE_PATH := "user://saves/battle_save.json"

func save_battle_state(data:Dictionary) -> void:
    var dir = DirAccess.open("user://saves")
    if dir == null:
        # FIX-ME: DirAccess.open returns null when directory doesn't exist.
        #         Consider handling OS errors and confirming creation success.
        DirAccess.make_dir_recursive("user://saves")
    var file = File.new()
    if file.open(SAVE_PATH, File.WRITE) == OK:
        file.store_string(to_json(data))
        file.close()

func load_battle_state() -> Dictionary:
    var file = File.new()
    if file.file_exists(SAVE_PATH) and file.open(SAVE_PATH, File.READ) == OK:
        var result = JSON.parse(file.get_as_text())
        file.close()
        if result.error == OK and typeof(result.result) == TYPE_DICTIONARY:
            return result.result
        push_warning("Malformed save file, starting fresh")
    return {}

func has_save() -> bool:
    var file = File.new()
    return file.file_exists(SAVE_PATH)

