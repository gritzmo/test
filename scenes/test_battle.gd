extends Node

# Handles fade-in/out and sets up the battle test scene.

onready var fade_rect: ColorRect = $FadeRect
onready var anim: AnimationPlayer = $AnimationPlayer
onready var controller: BattleController = $BattleController

func _ready() -> void:
    # Begin with a fade-in effect when the scene loads.
    if anim.has_animation("fade_in"):
        anim.play("fade_in")

    _setup_battle()
    controller.connect("battle_ended", self, "_on_battle_ended")
    controller.start_turn()

func _setup_battle() -> void:
    # Configure the battle controller and enemy AI.
    controller.player = controller.get_node("Player")
    controller.enemy = controller.get_node("Enemy")
    controller.ui = controller.get_node("UI")
    controller.status_manager = controller.get_node("StatusEffectManager")
    controller.sound_manager = controller.get_node("SoundManager")
    # Disable automatic start so we can control when the first turn begins
    controller.auto_start = false
    DialogueManager.set_enemy(controller.enemy)

    controller.attack_db = AttackDatabase.new()
    controller.attack_db.load_from_json("res://high_kick_hell/resources/attack_data.json")

    var enemy = controller.enemy
    var ai = enemy.get_node("EnemyAI")
    enemy.ai = ai
    ai.default_pattern = ["Roundhouse Kick", "Dropkick"]
    ai.scripted_turns = {
        1: {"dialogue": "You're late, Damien.", "attack": "Roundhouse Kick"},
        3: {"buff": "Focused Stance", "dialogue": "Discipline must escalate."},
        5: {"attack": "Dropkick", "debuff_player": "Dazed"}
    }

func _on_battle_ended(victory: bool) -> void:
    # Fade out then return to the main menu after a short delay.
    await get_tree().create_timer(1.0).timeout
    if anim.has_animation("fade_out"):
        anim.play("fade_out")
        await anim.animation_finished
    get_tree().change_scene_to_file("res://scenes/MainMenu.tscn")
