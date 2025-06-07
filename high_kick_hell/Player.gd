extends Node2D
class_name Player

signal action_requested(action_name)

"""
Holds Damien's combat statistics and basic actions. Values can be tweaked to
balance gameplay.
"""

# -- PRIMARY STATS --
# Maximum and current HP values
var max_hp := 100
var current_hp := 100

# Maximum and current SP (special/magic points)
var max_sp := 100
var current_sp := 50

# Core combat attributes
var strength := 10      # Affects damage dealt
var defense := 5        # Reduces damage taken
var agility := 8        # Influences dodge and crit
var stamina := 10       # Determines SP regeneration

# Derived values
var critical_chance := 0.1

var can_dodge := true

func _ready() -> void:
    """Initialize derived stats."""
    critical_chance = agility * 0.01

func apply_status(effect_data) -> void:
    var manager = get_parent().status_manager
    if manager:
        manager.apply_effect(self, effect_data)

# Called by UI or BattleController to execute actions
func taunt():
    emit_signal("action_requested", "taunt")
    DialogueManager.queue_line("Damien taunts defiantly!", "Damien")
    # CUSTOMIZATION POINT: Add taunt logic

func appease():
    emit_signal("action_requested", "appease")
    DialogueManager.queue_line("Damien tries to appease the foe.", "Damien")
    # CUSTOMIZATION POINT: Add appease logic

func use_item(item_id):
    emit_signal("action_requested", "item")
    DialogueManager.queue_line("Damien uses item %s." % item_id, "Damien")
    # CUSTOMIZATION POINT: Implement items

func dodge():
    emit_signal("action_requested", "dodge")
    DialogueManager.queue_line("Damien prepares to dodge.", "Damien")
    # CUSTOMIZATION POINT: Add dodge logic

func attempt_dodge() -> bool:
    """Returns true if Damien successfully dodges an incoming attack."""
    if not can_dodge:
        return false
    var chance = agility * 0.04
    return randf() < chance

func regenerate_sp() -> void:
    """Restores SP at the end of each turn."""
    current_sp = clamp(current_sp + stamina * 2, 0, max_sp)
