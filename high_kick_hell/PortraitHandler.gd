extends TextureRect

"""Manages Damien's portrait in the dialogue box.
Loads textures for different tones and handles fade in/out transitions."""

const Utils = preload("res://high_kick_hell/Utils.gd")

# Mapping of tone strings to portrait texture paths
# CUSTOMIZATION POINT: Add new tones or update texture paths as needed
var tone_textures := {
    "neutral": "res://art/damien_neutral.png",
    "angry": "res://art/damien_angry.png",
    "scared": "res://art/damien_scared.png",
    "smug": "res://art/damien_smug.png"
}

var fade_time := 0.25  # Seconds for fade animation

func show_portrait(tone:String) -> void:
    """Shows Damien's portrait with the given emotional tone."""
    var tex_path = tone_textures.get(tone, tone_textures.get("neutral"))
    if typeof(tex_path) == TYPE_STRING:
        # SAFETY: File may be missing
        var tex = Utils.safe_load(tex_path)
        if tex:
            texture = tex
    modulate.a = 0.0
    show()
    create_tween().tween_property(self, "modulate:a", 1.0, fade_time)

func hide_portrait() -> void:
    """Fades out and hides Damien's portrait."""
    if not visible:
        return
    var tween = create_tween()
    tween.tween_property(self, "modulate:a", 0.0, fade_time)
    tween.connect("finished", self, "hide")

