extends Control

# Handles button presses on the main menu and fade transitions.

onready var anim: AnimationPlayer = $AnimationPlayer

func _ready() -> void:
    # Fade in when menu loads.
    if anim.has_animation("fade_in"):
        anim.play("fade_in")
    $StartButton.connect("pressed", self, "_on_start_pressed")
    $ExitButton.connect("pressed", self, "_on_exit_pressed")

func _on_start_pressed() -> void:
    # Fade out then switch to the test battle scene.
    if anim.has_animation("fade_out"):
        anim.play("fade_out")
        await anim.animation_finished
    get_tree().change_scene_to_file("res://scenes/TestBattle.tscn")

func _on_exit_pressed() -> void:
    if anim.has_animation("fade_out"):
        anim.play("fade_out")
        await anim.animation_finished
    get_tree().quit()

