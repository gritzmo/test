extends Control
class_name BattleUI

"""
Handles all battle interface elements including command buttons,
HP/SP bars and cinematic attack windows.
"""

# TEST PLAN
# 1. Launch battle scene -> command bar visible.
# 2. Tap left/right keys to cycle highlight and hear move.wav.
# 3. Press ENTER on TAUNT -> select.wav plays and buttons disable.
# 4. Cinematic windows show images and text; hits shake the screen.
# 5. After the turn, input re-enables and missing assets only warn.

const Utils = preload("res://high_kick_hell/Utils.gd")

signal taunt_pressed
signal appease_pressed
signal item_pressed
signal dodge_pressed

# Basic UI elements are created or fetched at runtime so the demo works
# without a dedicated scene file. Buttons emit signals to the battle
# controller and the additional labels/images handle cinematic attacks.

onready var top_label : Label = null
onready var mid_image : TextureRect = null
onready var bottom_label : Label = null
onready var command_bar : HBoxContainer = null
onready var buttons := []
onready var darken_rect : ColorRect = null
onready var sfx_move : AudioStreamPlayer = null
onready var sfx_select : AudioStreamPlayer = null
var selected_index := 0
var input_enabled := true
onready var player_hp_bar : TextureProgressBar = null
onready var player_sp_bar : TextureProgressBar = null
onready var enemy_hp_bar : TextureProgressBar = null
onready var enemy_sp_bar : TextureProgressBar = null
onready var player_hp_label : Label = null
onready var player_sp_label : Label = null
onready var enemy_hp_label : Label = null
onready var enemy_sp_label : Label = null
onready var player_name_label : Label = null
onready var enemy_name_label : Label = null

func _ready() -> void:
    _ensure_nodes()
    # Connect each command button to its handler function
    for btn in buttons:
        match btn.name:
            "TauntButton":
                btn.connect("pressed", self, "_on_taunt_button_pressed")
            "AppeaseButton":
                btn.connect("pressed", self, "_on_appease_button_pressed")
            "ItemButton":
                btn.connect("pressed", self, "_on_item_button_pressed")
            "DodgeButton":
                btn.connect("pressed", self, "_on_dodge_button_pressed")
    update_player_bars(null)
    update_enemy_bars(null)
    _update_highlight()
    set_process_unhandled_input(true)

func _ensure_nodes() -> void:
    """Creates basic labels and buttons if they are missing."""
    if has_node("TopLabel"):
        top_label = $TopLabel
    else:
        top_label = Label.new()
        top_label.name = "TopLabel"
        top_label.anchor_left = 0.25
        top_label.anchor_right = 0.75
        top_label.margin_top = 20
        top_label.hide()
        add_child(top_label)

    if has_node("AttackImage"):
        mid_image = $AttackImage
    else:
        mid_image = TextureRect.new()
        mid_image.name = "AttackImage"
        mid_image.expand = true
        mid_image.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
        mid_image.anchor_left = 0.25
        mid_image.anchor_right = 0.75
        mid_image.anchor_top = 0.25
        mid_image.anchor_bottom = 0.75
        mid_image.hide()
        add_child(mid_image)

    if has_node("BottomLabel"):
        bottom_label = $BottomLabel
    else:
        bottom_label = Label.new()
        bottom_label.name = "BottomLabel"
        bottom_label.anchor_left = 0.1
        bottom_label.anchor_right = 0.9
        bottom_label.anchor_bottom = 0.95
        bottom_label.anchor_top = 0.8
        bottom_label.autowrap = true
        bottom_label.hide()
        add_child(bottom_label)

    if has_node("Darken"):
        darken_rect = $Darken
    else:
        darken_rect = ColorRect.new()
        darken_rect.name = "Darken"
        darken_rect.color = Color(0,0,0,0)
        darken_rect.anchor_left = 0
        darken_rect.anchor_right = 1
        darken_rect.anchor_top = 0
        darken_rect.anchor_bottom = 1
        darken_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
        darken_rect.hide()
        add_child(darken_rect)

    if has_node("CommandBar"):
        command_bar = $CommandBar
    else:
        command_bar = HBoxContainer.new()
        command_bar.name = "CommandBar"
        command_bar.anchor_left = 0.4
        command_bar.anchor_right = 0.6
        command_bar.anchor_top = 0.8
        command_bar.anchor_bottom = 0.9
        command_bar.alignment = BoxContainer.ALIGN_CENTER
        add_child(command_bar)

    var button_names = ["TauntButton", "AppeaseButton", "ItemButton", "DodgeButton"]
    for bn in button_names:
        var btn:TextureButton
        if command_bar.has_node(bn):
            btn = command_bar.get_node(bn)
        else:
            btn = TextureButton.new()
            btn.name = bn
            btn.expand = true
            var label = Label.new()
            label.text = bn.replace("Button", "").capitalize()
            btn.add_child(label)
            command_bar.add_child(btn)
        buttons.append(btn)
    # CUSTOMIZATION POINT: assign textures or animations to the buttons above

    if has_node("SFX_Move"):
        sfx_move = $SFX_Move
    else:
        sfx_move = AudioStreamPlayer.new()
        sfx_move.name = "SFX_Move"
        add_child(sfx_move)
    sfx_move.stream = Utils.safe_load("res://high_kick_hell/sounds/move.wav")

    if has_node("SFX_Select"):
        sfx_select = $SFX_Select
    else:
        sfx_select = AudioStreamPlayer.new()
        sfx_select.name = "SFX_Select"
        add_child(sfx_select)
    sfx_select.stream = Utils.safe_load("res://high_kick_hell/sounds/select.wav")

    _setup_bars()

func _setup_bars() -> void:
    """Creates HP/SP bars for player and enemy."""
    if has_node("PlayerHP"):
        player_hp_bar = $PlayerHP
    else:
        player_hp_bar = TextureProgressBar.new()
        player_hp_bar.name = "PlayerHP"
        player_hp_bar.anchor_left = 0.02
        player_hp_bar.anchor_top = 0.02
        player_hp_bar.anchor_right = 0.25
        player_hp_bar.anchor_bottom = 0.06
        add_child(player_hp_bar)

    if has_node("PlayerHPLabel"):
        player_hp_label = $PlayerHPLabel
    else:
        player_hp_label = Label.new()
        player_hp_label.name = "PlayerHPLabel"
        player_hp_label.anchor_left = player_hp_bar.anchor_left
        player_hp_label.anchor_top = player_hp_bar.anchor_bottom
        player_hp_label.anchor_right = player_hp_bar.anchor_right
        player_hp_label.anchor_bottom = player_hp_bar.anchor_bottom + 0.03
        add_child(player_hp_label)

    if has_node("PlayerSP"):
        player_sp_bar = $PlayerSP
    else:
        player_sp_bar = TextureProgressBar.new()
        player_sp_bar.name = "PlayerSP"
        player_sp_bar.anchor_left = 0.02
        player_sp_bar.anchor_top = 0.07
        player_sp_bar.anchor_right = 0.25
        player_sp_bar.anchor_bottom = 0.11
        add_child(player_sp_bar)

    if has_node("PlayerSPLabel"):
        player_sp_label = $PlayerSPLabel
    else:
        player_sp_label = Label.new()
        player_sp_label.name = "PlayerSPLabel"
        player_sp_label.anchor_left = player_sp_bar.anchor_left
        player_sp_label.anchor_top = player_sp_bar.anchor_bottom
        player_sp_label.anchor_right = player_sp_bar.anchor_right
        player_sp_label.anchor_bottom = player_sp_bar.anchor_bottom + 0.03
        add_child(player_sp_label)

    if has_node("EnemyHP"):
        enemy_hp_bar = $EnemyHP
    else:
        enemy_hp_bar = TextureProgressBar.new()
        enemy_hp_bar.name = "EnemyHP"
        enemy_hp_bar.anchor_left = 0.75
        enemy_hp_bar.anchor_top = 0.02
        enemy_hp_bar.anchor_right = 0.98
        enemy_hp_bar.anchor_bottom = 0.06
        add_child(enemy_hp_bar)

    if has_node("EnemyHPLabel"):
        enemy_hp_label = $EnemyHPLabel
    else:
        enemy_hp_label = Label.new()
        enemy_hp_label.name = "EnemyHPLabel"
        enemy_hp_label.anchor_left = enemy_hp_bar.anchor_left
        enemy_hp_label.anchor_top = enemy_hp_bar.anchor_bottom
        enemy_hp_label.anchor_right = enemy_hp_bar.anchor_right
        enemy_hp_label.anchor_bottom = enemy_hp_bar.anchor_bottom + 0.03
        add_child(enemy_hp_label)

    if has_node("EnemySP"):
        enemy_sp_bar = $EnemySP
    else:
        enemy_sp_bar = TextureProgressBar.new()
        enemy_sp_bar.name = "EnemySP"
        enemy_sp_bar.anchor_left = 0.75
        enemy_sp_bar.anchor_top = 0.07
        enemy_sp_bar.anchor_right = 0.98
        enemy_sp_bar.anchor_bottom = 0.11
        add_child(enemy_sp_bar)

    if has_node("EnemySPLabel"):
        enemy_sp_label = $EnemySPLabel
    else:
        enemy_sp_label = Label.new()
        enemy_sp_label.name = "EnemySPLabel"
        enemy_sp_label.anchor_left = enemy_sp_bar.anchor_left
        enemy_sp_label.anchor_top = enemy_sp_bar.anchor_bottom
        enemy_sp_label.anchor_right = enemy_sp_bar.anchor_right
        enemy_sp_label.anchor_bottom = enemy_sp_bar.anchor_bottom + 0.03
        add_child(enemy_sp_label)

func _on_taunt_button_pressed():
    emit_signal("taunt_pressed")

func _on_appease_button_pressed():
    emit_signal("appease_pressed")

func _on_item_button_pressed():
    emit_signal("item_pressed")

func _on_dodge_button_pressed():
    emit_signal("dodge_pressed")

func set_input_enabled(enabled:bool) -> void:
    """Enables or disables all command buttons."""
    input_enabled = enabled
    for btn in buttons:
        btn.disabled = not enabled

func play_ui_sfx(kind:String) -> void:
    """Plays move or select UI sounds."""
    match kind:
        "move":
            if sfx_move and sfx_move.stream:
                sfx_move.play()
        "select":
            if sfx_select and sfx_select.stream:
                sfx_select.play()

func _update_highlight() -> void:
    """Visually marks the currently selected command button."""
    for i in range(buttons.size()):
        var btn = buttons[i]
        btn.scale = i == selected_index ? Vector2(1.2,1.2) : Vector2.ONE

func _unhandled_input(event:InputEvent) -> void:
    """Handles keyboard navigation for the command bar."""
    if not input_enabled:
        return
    if event.is_action_pressed("ui_left"):
        selected_index = (selected_index - 1 + buttons.size()) % buttons.size()
        _update_highlight()
        play_ui_sfx("move")
    elif event.is_action_pressed("ui_right"):
        selected_index = (selected_index + 1) % buttons.size()
        _update_highlight()
        play_ui_sfx("move")
    elif event.is_action_pressed("ui_accept"):
        play_ui_sfx("select")
        buttons[selected_index].emit_signal("pressed")

func show_attack_name(name:String) -> void:
    """Displays the attack name briefly at the top of the screen."""
    top_label.text = name
    top_label.modulate.a = 0.0
    top_label.show()
    var t = create_tween()
    t.tween_property(top_label, "modulate:a", 1.0, 0.25)
    await t.finished
    await get_tree().create_timer(1.5).timeout
    var fade = create_tween()
    fade.tween_property(top_label, "modulate:a", 0.0, 0.25)
    await fade.finished
    top_label.hide()

func show_attack_image(path:String) -> void:
    """Fades in an image over the action area."""
    if path != "":
        # SAFETY: File may be missing
        var tex = Utils.safe_load(path)
        if tex:
            mid_image.texture = tex
    mid_image.modulate.a = 0.0
    mid_image.show()
    var t = create_tween()
    t.tween_property(mid_image, "modulate:a", 1.0, 0.2)
    await t.finished

func hide_attack_image() -> void:
    """Fades out the attack image."""
    var t = create_tween()
    t.tween_property(mid_image, "modulate:a", 0.0, 0.2)
    await t.finished
    mid_image.hide()

func darken_screen() -> void:
    """Fades in a semi-transparent overlay to focus on the attack."""
    darken_rect.modulate.a = 0.0
    darken_rect.show()
    var t = create_tween()
    t.tween_property(darken_rect, "modulate:a", 0.5, 0.2)
    await t.finished

func brighten_screen() -> void:
    """Removes the overlay after the attack."""
    var t = create_tween()
    t.tween_property(darken_rect, "modulate:a", 0.0, 0.2)
    await t.finished
    darken_rect.hide()

func show_flavor_text(text:String) -> void:
    """Shows temporary flavor narration at the bottom of the screen."""
    bottom_label.text = text
    bottom_label.modulate.a = 0.0
    bottom_label.show()
    var t = create_tween()
    t.tween_property(bottom_label, "modulate:a", 1.0, 0.2)
    await t.finished
    await get_tree().create_timer(1.5).timeout
    var fade = create_tween()
    fade.tween_property(bottom_label, "modulate:a", 0.0, 0.2)
    await fade.finished
    bottom_label.hide()

# CUSTOMIZATION POINT: Extend with camera shake or additional pop-ups

func update_player_bars(player) -> void:
    """Refreshes the player's HP and SP bar displays."""
    if not player:
        return
    player_hp_bar.max_value = player.max_hp
    player_hp_bar.value = player.current_hp
    player_sp_bar.max_value = player.max_sp
    player_sp_bar.value = player.current_sp
    player_hp_label.text = "HP: %d / %d" % [player.current_hp, player.max_hp]
    player_sp_label.text = "SP: %d / %d" % [player.current_sp, player.max_sp]
    if not player_name_label:
        player_name_label = Label.new()
        player_name_label.anchor_left = player_hp_bar.anchor_left
        player_name_label.anchor_right = player_hp_bar.anchor_right
        player_name_label.anchor_bottom = player_hp_bar.anchor_top
        player_name_label.anchor_top = player_hp_bar.anchor_top - 0.03
        add_child(player_name_label)
    player_name_label.text = "Damien"

func update_enemy_bars(enemy) -> void:
    """Refreshes the enemy's HP and SP bar displays."""
    if not enemy:
        return
    enemy_hp_bar.max_value = enemy.max_hp
    enemy_hp_bar.value = enemy.current_hp
    enemy_sp_bar.max_value = enemy.max_sp
    enemy_sp_bar.value = enemy.current_sp
    enemy_hp_label.text = "HP: %d / %d" % [enemy.current_hp, enemy.max_hp]
    enemy_sp_label.text = "SP: %d / %d" % [enemy.current_sp, enemy.max_sp]
    if not enemy_name_label:
        enemy_name_label = Label.new()
        enemy_name_label.anchor_left = enemy_hp_bar.anchor_left
        enemy_name_label.anchor_right = enemy_hp_bar.anchor_right
        enemy_name_label.anchor_bottom = enemy_hp_bar.anchor_top
        enemy_name_label.anchor_top = enemy_hp_bar.anchor_top - 0.03
        add_child(enemy_name_label)
    enemy_name_label.text = enemy.name

# End of BattleUI.gd - provides buttons and cinematic helpers for combat
