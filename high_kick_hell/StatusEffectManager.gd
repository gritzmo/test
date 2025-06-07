extends Node

"""
Keeps track of all buffs, debuffs and status effects in battle.
Call `apply_effect(target, effect_data)` to attach a new effect and
`update_effects()` once per turn to process durations.
"""

# Manages StatusEffect instances for all combatants.
# Effects are applied with apply_effect(target, effect) and processed each turn
# with update_effects().

# Signals for external systems (UI, sound, etc.)
signal effect_applied(target, effect_name)
signal effect_expired(target, effect_name)
signal effect_triggered(target, effect_name)

var active_effects := []   # Array storing dictionaries {target, effect}

func apply_effect(target, effect_data) -> void:
    """Adds a new status effect to the given target."""
    var effect : StatusEffect = effect_data if effect_data is StatusEffect else StatusEffect.new(effect_data)
    effect.apply(target)
    active_effects.append({"target": target, "effect": effect})
    emit_signal("effect_applied", target, effect.name)
    # Helpful debug output for developers
    print("Applied", effect.name, "to", target.name)

func remove_effect(target, effect_name:String) -> void:
    """Forces an effect to expire immediately."""
    for i in range(active_effects.size() - 1, -1, -1):
        var data = active_effects[i]
        if data.target == target and data.effect.name == effect_name:
            data.effect.expire(target)
            active_effects.remove(i)
            emit_signal("effect_expired", target, effect_name)

func update_effects() -> void:
    """Processes all active effects once per turn."""
    for i in range(active_effects.size() - 1, -1, -1):
        var data = active_effects[i]
        var effect : StatusEffect = data.effect
        effect.process_turn(data.target)
        print(effect.name, "ticks on", data.target.name)
        emit_signal("effect_triggered", data.target, effect.name)
        if effect.duration <= 0:
            effect.expire(data.target)
            active_effects.remove(i)
            emit_signal("effect_expired", data.target, effect.name)
            print(effect.name, "expired on", data.target.name)

func get_effects_for(target) -> Array:
    """Returns an array of StatusEffect instances applied to the target."""
    return [d.effect for d in active_effects if d.target == target]
