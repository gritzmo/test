extends Node2D
class_name Enemy

const Utils = preload("res://high_kick_hell/Utils.gd")

signal action_requested(action_name)

"""
Enemy combatant with base statistics and pose logic.
"""

# -- PRIMARY STATS --
var max_hp := 100
var current_hp := 80

var max_sp := 100
var current_sp := 40

var strength := 8
var defense := 4
var agility := 6
var stamina := 8

# Derived value updated on ready
var critical_chance := 0.06

# Pattern array to choose attacks (strings referencing attack names in AttackDatabase)
var attack_pattern = []
var pattern_index = 0
var ai : EnemyAI = null
var pose_sprites := {
    "neutral": "res://art/enemy_pose_neutral.png",
    "angry": "res://art/enemy_pose_angry.png",
    "smug": "res://art/enemy_pose_smug.png",
    "laughing": "res://art/enemy_pose_laughing.png"
} # CUSTOMIZATION POINT: Add or change enemy pose textures

onready var sprite: Sprite = null

func apply_buff(name:String) -> void:
    var manager = get_parent().status_manager
    if manager:
        manager.apply_effect(self, {"name": name, "type": "buff", "duration": 2})

func apply_debuff_to_player(name:String) -> void:
    var controller = get_parent()
    if controller and controller.player and controller.status_manager:
        controller.status_manager.apply_effect(controller.player, {"name": name, "type": "debuff", "duration": 2})

func _ready():
    pattern_index = 0
    if has_node("EnemyAI"):
        ai = $EnemyAI
    if has_node("Sprite"):
        sprite = $Sprite
    critical_chance = agility * 0.01

func choose_attack(turn_number:int):
    if ai:
        var scripted_attack = ai.choose_attack(turn_number)
        if scripted_attack != "":
            emit_signal("action_requested", scripted_attack)
            return scripted_attack
    if attack_pattern.size() == 0:
        return null
    var attack_name = attack_pattern[pattern_index % attack_pattern.size()]
    pattern_index += 1
    emit_signal("action_requested", attack_name)
    return attack_name

func execute_attack(attack_data):
    DialogueManager.queue_line("Enemy uses %s!" % attack_data.name, "Enemy")
    # CUSTOMIZATION POINT: Add enemy attack logic

func change_pose(tone:String) -> void:
    """Switches the enemy's sprite based on the provided tone."""
    if sprite == null:
        return
    var tex_path = pose_sprites.get(tone, pose_sprites.get("neutral"))
    if typeof(tex_path) == TYPE_STRING:
        # SAFETY: File may be missing
        var tex = Utils.safe_load(tex_path)
        if tex:
            sprite.texture = tex

func on_turn_started(turn_number:int) -> void:
    if ai and ai.scripted_turns.has(turn_number):
        pass # placeholder for additional per-turn effects

func regenerate_sp() -> void:
    """Restores SP based on stamina."""
    current_sp = clamp(current_sp + stamina * 2, 0, max_sp)

func attempt_dodge() -> bool:
    """Enemy dodge chance based on agility."""
    var chance = agility * 0.04
    return randf() < chance

