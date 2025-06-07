extends Node

# Example demo that sets up the battle

func _ready():
    var controller = $BattleController
    controller.player = controller.get_node("Player")
    controller.enemy = controller.get_node("Enemy")
    controller.ui = controller.get_node("UI")
    controller.status_manager = controller.get_node("StatusEffectManager")

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
    # Start the battle
    controller.start_turn()
