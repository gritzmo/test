extends Node

"""
Provides basic stat calculations for combat. Adjust these formulas to
balance gameplay.
"""

# -- BATTLE MATH --

static func calculate_damage(attacker, defender, attack_data:Dictionary) -> int:
    """Returns final damage value after applying strength and defense."""
    var base_damage = attack_data.get("damage", attack_data.get("power", 0))
    var raw = base_damage + attacker.strength - defender.defense
    return clamp(raw, 1, 999)

static func dodge_chance(defender) -> float:
    """How likely the defender is to dodge an attack."""
    return defender.agility * 0.04

static func critical_chance(attacker) -> float:
    """Critical hit chance based on agility."""
    return attacker.agility * 0.01

static func regenerate_sp(character) -> void:
    """Restores SP based on stamina."""
    character.current_sp = clamp(character.current_sp + character.stamina * 2,
        0, character.max_sp)
