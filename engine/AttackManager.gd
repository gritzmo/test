extends Node
class_name AttackManager

"""Executes data-driven attacks using cinematic windows."""

var ui: BattleUI = null
var sound_manager: SoundManager = null
var stats = preload("res://engine/util/constants.gd")

func run_attack(attacker, target, attack_data:Dictionary) -> void:
    """Runs the full cinematic attack sequence."""
    if ui:
        ui.set_input_enabled(false)
        await ui.darken_screen()
        await ui.show_attack_name(attack_data.get("name", ""))
        await ui.show_attack_image(attack_data.get("start_image", ""))
        await ui.show_flavor_text(attack_data.get("start_text", ""))

    var outcome = "hit"
    if attack_data.get("can_be_dodged", false) and target.has_method("attempt_dodge"):
        if target.attempt_dodge():
            outcome = "dodge"
    elif randf() < attack_data.get("miss_chance", 0.0):
        outcome = "miss"

    var critical = false
    if outcome == "hit" and randf() < stats.critical_chance(attacker):
        critical = true

    match outcome:
        "hit":
            if ui:
                await ui.show_attack_image(attack_data.get("hit_image", ""))
                var txt = attack_data.get("hit_text", "")
                if critical:
                    txt = attack_data.get("critical_text", txt)
                await ui.show_flavor_text(txt)
            _apply_damage(attacker, target, attack_data, critical)
            if sound_manager:
                sound_manager.play_sound(critical ? "crit" : "hit")
        "dodge":
            if ui:
                await ui.show_attack_image(attack_data.get("dodge_image", ""))
                await ui.show_flavor_text(attack_data.get("dodge_text", ""))
            if sound_manager:
                sound_manager.play_sound("miss")
        "miss":
            if ui:
                await ui.show_attack_image(attack_data.get("miss_image", ""))
                await ui.show_flavor_text(attack_data.get("miss_text", ""))
            if sound_manager:
                sound_manager.play_sound("miss")

    if ui:
        await ui.hide_attack_image()
        await ui.brighten_screen()
        ui.set_input_enabled(true)

func _apply_damage(attacker, target, attack_data:Dictionary, critical:bool) -> void:
    var dmg = stats.calculate_damage(attacker, target, attack_data)
    if critical:
        dmg = int(round(dmg * BattleController.CRIT_MULTIPLIER))
    target.current_hp = max(target.current_hp - dmg, 0)

