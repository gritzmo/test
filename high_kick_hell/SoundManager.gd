extends Node

"""
Plays combat sound effects such as hits, misses and criticals.
Attach this node to the battle scene and call `play_sound()`
with "hit", "miss" or "crit".
"""

const Utils = preload("res://high_kick_hell/Utils.gd")

onready var hit_audio : AudioStreamPlayer = $HitAudio
onready var miss_audio : AudioStreamPlayer = $MissAudio
onready var crit_audio : AudioStreamPlayer = $CritAudio

func _ready() -> void:
    """Loads audio files safely when the scene is ready."""
    if hit_audio:
        hit_audio.stream = Utils.safe_load("res://high_kick_hell/sounds/hit.wav")
    else:
        push_warning("HitAudio node missing in SoundManager")

    if miss_audio:
        miss_audio.stream = Utils.safe_load("res://high_kick_hell/sounds/miss.wav")
    else:
        push_warning("MissAudio node missing in SoundManager")

    if crit_audio:
        crit_audio.stream = Utils.safe_load("res://high_kick_hell/sounds/crit.wav")
    else:
        push_warning("CritAudio node missing in SoundManager")

func play_sound(kind:String) -> void:
    """Plays a sound based on the provided kind string."""
    match kind:
        "hit":
            if hit_audio.stream:
                hit_audio.play()
        "miss":
            if miss_audio.stream:
                miss_audio.play()
        "crit":
            if crit_audio.stream:
                crit_audio.play()
