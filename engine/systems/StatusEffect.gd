extends Resource
class_name StatusEffect

# Resource representing a single status effect applied to a character.
# Callbacks can be overridden or provided via dictionary when creating the effect.

export(String) var name = ""
export(String) var type = "buff" # buff, debuff, status
export(int) var duration = 1
export(String) var icon = ""

var on_apply : Callable = null
var on_turn : Callable = null
var on_expire : Callable = null

func _init(data:Dictionary = {}):
    name = data.get("name", name)
    type = data.get("type", type)
    duration = data.get("duration", duration)
    icon = data.get("icon", icon)
    on_apply = data.get("on_apply", on_apply)
    on_turn = data.get("on_turn", on_turn)
    on_expire = data.get("on_expire", on_expire)

func apply(target) -> void:
    if on_apply and on_apply.is_valid():
        on_apply.call(target)

func process_turn(target) -> void:
    if on_turn and on_turn.is_valid():
        on_turn.call(target)
    duration -= 1

func expire(target) -> void:
    if on_expire and on_expire.is_valid():
        on_expire.call(target)
