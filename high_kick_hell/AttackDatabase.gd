extends Resource
class_name AttackDatabase

# Holds attack data loaded from JSON. Each attack entry can include
# fields like images, damage values and flavor text used for the
# cinematic attack system.

var attacks = {}

const Utils = preload("res://high_kick_hell/Utils.gd")

func load_from_json(path:String) -> void:
    """Loads attack definitions from a JSON file."""
    var file = File.new()
    if not file.file_exists(path):
        push_warning("Attack data file not found: %s" % path)
        return
    file.open(path, File.READ)
    var result = JSON.parse(file.get_as_text())
    file.close()
    if result.error == OK and typeof(result.result) == TYPE_DICTIONARY:
        attacks = result.result
    else:
        push_warning("Invalid attack data in %s" % path)

func get_attack(name):
    return attacks.get(name, null)

# CUSTOMIZATION POINT: add methods to register new attacks at runtime
func register_attack(name, data):
    attacks[name] = data
