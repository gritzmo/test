extends Node

"""
Controls the overall flow of a single battle.
Handles the turn state machine and delegates
actions to the Player and Enemy nodes.
"""

# Possible phases of the battle turn cycle
const STATE_WAIT_FOR_PLAYER = 0    # Waiting for the player to choose an action
const STATE_PLAYER_ACTION = 1      # Player action is being executed
const STATE_ENEMY_ACTION = 2       # Enemy action is being executed
const STATE_END_TURN = 3           # Cleanup before the next turn

const Stats = preload("res://high_kick_hell/Stats.gd")

# Signals emitted during battle
signal turn_started(turn_owner)             # Emitted when a new combatant's turn begins
signal action_started(actor, action_name)   # Emitted when an action animation begins
signal damage_dealt(actor, target, amount)  # Emitted when damage numbers are applied
signal battle_ended(victory)                # Emitted when the fight ends
signal turn_changed(turn_number)            # Tracks total rounds so far

var player : Player                           # Reference to the player's node
var enemy : Enemy                             # Current enemy combatant
var ui : BattleUI                             # Handles button presses and text
var attack_db : AttackDatabase                # Loaded attack definitions
var status_manager : StatusEffectManager      # Applies buffs and debuffs
var sound_manager : SoundManager              # Handles combat sound effects

const CRIT_MULTIPLIER := 1.5                  # Damage bonus when a critical hits

var can_act := true                           # If false, player input is locked

var state = STATE_WAIT_FOR_PLAYER             # Current phase of the state machine
var turn_number := 0                          # Incremented each new round
# If true, the first turn starts automatically when the node enters the scene.
# Set to false when another script manually calls start_turn().
export var auto_start := true

func _ready():
    """Grabs child nodes if not assigned and connects UI signals."""
    # Auto-detect common children so the demo works with minimal setup.
    if not player and has_node("Player"):
        player = get_node("Player")
    if not enemy and has_node("Enemy"):
        enemy = get_node("Enemy")
    if not ui and has_node("UI"):
        ui = get_node("UI")
    if not status_manager and has_node("StatusEffectManager"):
        status_manager = get_node("StatusEffectManager")
    if not sound_manager and has_node("SoundManager"):
        sound_manager = get_node("SoundManager")

    if ui:
        # Connect button signals from the UI to handler methods.
        if not ui.is_connected("taunt_pressed", self, "_on_ui_taunt"):
            ui.connect("taunt_pressed", self, "_on_ui_taunt")
        if not ui.is_connected("appease_pressed", self, "_on_ui_appease"):
            ui.connect("appease_pressed", self, "_on_ui_appease")
        if not ui.is_connected("item_pressed", self, "_on_ui_item"):
            ui.connect("item_pressed", self, "_on_ui_item")
        if not ui.is_connected("dodge_pressed", self, "_on_ui_dodge"):
            ui.connect("dodge_pressed", self, "_on_ui_dodge")

    # Start automatically unless another script will handle it.
    if auto_start and turn_number == 0:
        start_turn()

func start_turn():
    """Begins a new round of combat."""
    turn_number += 1
    state = STATE_WAIT_FOR_PLAYER
    can_act = true
    if ui:
        ui.set_input_enabled(true)
        ui.update_player_bars(player)
        ui.update_enemy_bars(enemy)
    emit_signal("turn_started", player)
    emit_signal("turn_changed", turn_number)
    check_turn_events()

func _on_ui_taunt():
    """Called when the player presses the Taunt button."""
    if state == STATE_WAIT_FOR_PLAYER and can_act:
        can_act = false
        if ui:
            ui.set_input_enabled(false)
        state = STATE_PLAYER_ACTION
        emit_signal("action_started", player, "taunt")
        player.taunt()
        var s = _process_player_action("taunt")
        if s is GDScriptFunctionState:
            await s.completed

func _on_ui_appease():
    """Called when the player presses the Appease button."""
    if state == STATE_WAIT_FOR_PLAYER and can_act:
        can_act = false
        if ui:
            ui.set_input_enabled(false)
        state = STATE_PLAYER_ACTION
        emit_signal("action_started", player, "appease")
        player.appease()
        var s = _process_player_action("appease")
        if s is GDScriptFunctionState:
            await s.completed

func _on_ui_item():
    """Called when the player selects Item."""
    if state == STATE_WAIT_FOR_PLAYER and can_act:
        can_act = false
        if ui:
            ui.set_input_enabled(false)
        state = STATE_PLAYER_ACTION
        emit_signal("action_started", player, "item")
        player.use_item("potion")
        var s = _process_player_action("item")
        if s is GDScriptFunctionState:
            await s.completed

func _on_ui_dodge():
    """Called when the player chooses to Dodge."""
    if state == STATE_WAIT_FOR_PLAYER and can_act:
        can_act = false
        if ui:
            ui.set_input_enabled(false)
        state = STATE_PLAYER_ACTION
        emit_signal("action_started", player, "dodge")
        player.dodge()
        var s = _process_player_action("dodge")
        if s is GDScriptFunctionState:
            await s.completed

func _process_player_action(action_name):
    """Handles any follow-up after a player action is chosen."""
    # CUSTOMIZATION POINT: Apply player action effects or animations
    # Short delay to simulate the player's animation
    await get_tree().create_timer(0.5).timeout
    state = STATE_ENEMY_ACTION
    # Using call_deferred ensures the enemy turn runs after the current frame.
    call_deferred("enemy_turn")

func enemy_turn():
    """Executes the enemy's turn, waiting for any dialogue if necessary."""
    emit_signal("turn_started", enemy)

    # EnemyAI.choose_attack may yield (for dialogue). Handle both cases safely.
    var choice = enemy.choose_attack(turn_number)
    if choice is GDScriptFunctionState:
        await choice.completed
        var attack_name = choice.get_result()
    else:
        var attack_name = choice

    if attack_name:
        var attack = attack_db.get_attack(attack_name)
        if attack:
            emit_signal("action_started", enemy, attack_name)
            await run_attack_sequence(enemy, player, attack)

    state = STATE_END_TURN
    _end_turn()

func check_turn_events():
    """Called at the start of every round to trigger timed effects."""
    # CUSTOMIZATION POINT: Insert custom per-turn logic or dialogue here.
    if enemy and enemy.has_method("on_turn_started"):
        enemy.on_turn_started(turn_number)
    if player and player.has_method("on_turn_started"):
        player.on_turn_started(turn_number)
    if status_manager:
        status_manager.update_effects()

func _apply_attack_damage(attacker, target, attack, is_critical:bool=false):
    """Calculates and applies damage using stat-based formulas."""
    if attack == null:
        return
    var dmg = Stats.calculate_damage(attacker, target, attack)
    if is_critical:
        # CUSTOMIZATION POINT: Modify critical damage multiplier here
        dmg = int(round(dmg * CRIT_MULTIPLIER))
    target.current_hp = max(target.current_hp - dmg, 0)
    emit_signal("damage_dealt", attacker, target, dmg)
    if ui:
        if target == player:
            ui.update_player_bars(player)
        else:
            ui.update_enemy_bars(enemy)

func run_attack_sequence(attacker, target, attack:Dictionary) -> void:
    """Plays the cinematic attack sequence using data-driven fields."""
    if ui:
        ui.set_input_enabled(false)
    can_act = false

    # 1. Show the attack name at the top of the screen
    if ui:
        await ui.darken_screen()
        await ui.show_attack_name(attack.get("name", ""))

    # 2. Display the starting pose image
    if ui:
        await ui.show_attack_image(attack.get("start_image", ""))

    # 3. Flavor text describing the attack wind-up
    if ui:
        await ui.show_flavor_text(attack.get("start_text", ""))

    # -- Determine outcome: hit, dodge or miss
    var outcome = "hit"
    var miss_chance = attack.get("miss_chance", 0.0)
    if randf() < miss_chance:
        outcome = "miss"
    elif attack.get("can_be_dodged", false) and target and target.has_method("attempt_dodge"):
        if target.attempt_dodge():
            outcome = "dodge"

    var is_critical = false
    if outcome == "hit":
        var crit_chance = Stats.critical_chance(attacker)
        if randf() < crit_chance:
            is_critical = true

    match outcome:
        "hit":
            if ui:
                await ui.show_attack_image(attack.get("hit_image", ""))
                var text = attack.get("hit_text", "")
                if is_critical:
                    text = attack.get("critical_text", text)
                await ui.show_flavor_text(text)
            _apply_attack_damage(attacker, target, attack, is_critical)
            if sound_manager:
                sound_manager.play_sound(is_critical ? "crit" : "hit")
        "dodge":
            if ui:
                await ui.show_attack_image(attack.get("dodge_image", ""))
                await ui.show_flavor_text(attack.get("dodge_text", ""))
            if sound_manager:
                sound_manager.play_sound("miss")
        "miss":
            if ui:
                await ui.show_attack_image(attack.get("miss_image", ""))
                await ui.show_flavor_text(attack.get("miss_text", ""))
            if sound_manager:
                sound_manager.play_sound("miss")

    if ui:
        await ui.hide_attack_image()
        await ui.brighten_screen()

    can_act = true
    if ui:
        ui.set_input_enabled(true)

func _end_turn():
    """Checks for victory conditions and begins the next turn."""
    # CUSTOMIZATION POINT: apply status effects between turns
    if player:
        player.regenerate_sp()
        if ui:
            ui.update_player_bars(player)
    if enemy:
        enemy.regenerate_sp()
        if ui:
            ui.update_enemy_bars(enemy)

    if player.current_hp <= 0:
        emit_signal("battle_ended", false)
        return
    if enemy.current_hp <= 0:
        emit_signal("battle_ended", true)
        return
    start_turn()

# End of BattleController.gd - coordinates player and enemy turns
