extends Node

"""
Singleton used to display Undertale-style dialogue one letter at a time.
Use `start_dialogue()` with an array of dictionaries to show lines with
optional speaker and tone information.  Each entry may include a
`"text_speed"` value controlling how fast the text appears.
"""

# Autoload singleton that controls an Undertale-style dialogue system.
# Call `start_dialogue(lines)` with an array of dictionaries:
# {"text": "Hello", "speaker": "Damien", "tone": "smug"}

signal dialogue_finished

const Utils = preload("res://high_kick_hell/Utils.gd")

const DIALOGUE_BOX_SCENE = preload("res://high_kick_hell/dialogue/DialogueBox.tscn")

# Mapping of speaker names to blip sounds. Add new entries to support
# additional characters.
var blip_sounds = {
    "reina": Utils.safe_load("res://high_kick_hell/blips/reina.wav"),
    "dolly": Utils.safe_load("res://high_kick_hell/blips/dolly.wav"),
    "default": Utils.safe_load("res://high_kick_hell/blips/default.wav")
}

# Seconds per character for lines that omit a custom speed
# CUSTOMIZATION POINT: change default_text_speed here
var default_text_speed := 0.03

var box : Control = null
var text_label : Label = null
var name_label : Label = null
var portrait_handler : PortraitHandler = null
var enemy : Node = null
var audio_player : AudioStreamPlayer = null

var current_lines = []
var current_index = 0
var char_index = 0
var displaying = false
var active = false
var time_accum = 0.0
var current_text_speed = default_text_speed

func set_enemy(e:Node) -> void:
    """Assigns the current enemy so we can change its pose during dialogue."""
    enemy = e

func queue_line(text:String, speaker:String="") -> void:
    """Adds a single line of dialogue to the queue.
    If no dialogue is currently playing, it will start immediately."""
    var line = {"text": text, "speaker": speaker}
    if active:
        current_lines.append(line)
    else:
        start_dialogue([line])

func _ready():
    """Creates the dialogue box UI and prepares processing."""
    # Preload the dialogue box so we can reuse it.
    box = DIALOGUE_BOX_SCENE.instance()
    add_child(box)
    text_label = box.get_node("Panel/TextLabel")
    name_label = box.get_node("Panel/NameLabel")
    portrait_handler = box.get_node("Panel/Portrait")
    audio_player = AudioStreamPlayer.new()
    box.add_child(audio_player)
    box.hide()

    # Ensure that _process will run every frame.
    set_process(true)

func start_dialogue(lines:Array) -> void:
    """Begins displaying an array of dialogue lines."""
    # Interrupt any existing dialogue and start fresh.
    current_lines = lines
    current_index = 0
    char_index = 0
    active = true
    box.show()
    _apply_line(current_lines[current_index])

func _process(delta:float) -> void:
    """Handles the typewriter effect each frame."""
    if not active:
        return
    if not displaying:
        return
    time_accum += delta
    var line = current_lines[current_index]
    var text = line["text"] if line is Dictionary else String(line)
    if char_index < text.length():
        if time_accum >= current_text_speed:
            char_index += 1
            text_label.text = text.substr(0, char_index)
            _play_blip(line)
            time_accum = 0.0
    else:
        displaying = false

    if Input.is_action_just_pressed("ui_accept"):
        _on_accept_pressed()

func _on_accept_pressed() -> void:
    """Skips text or moves to the next line when the player presses ENTER."""
    var line = current_lines[current_index]
    var text = line["text"] if line is Dictionary else String(line)
    if displaying:
        # Finish the line instantly
        char_index = text.length()
        text_label.text = text
        displaying = false
    else:
        # Advance to the next line
        current_index += 1
        if current_index >= current_lines.size():
            _end_dialogue()
        else:
            _apply_line(current_lines[current_index])

func _apply_line(line):
    """Loads the next line into the dialogue box and updates portraits/poses."""
    char_index = 0
    displaying = true
    time_accum = 0.0
    current_text_speed = default_text_speed

    text_label.text = ""
    name_label.text = ""
    if line is Dictionary:
        name_label.text = line.get("speaker", "")
        var tone = line.get("tone", "neutral")
        current_text_speed = line.get("text_speed", default_text_speed)
        var speaker = name_label.text
        if speaker == "Damien" and portrait_handler:
            portrait_handler.show_portrait(tone)
            if enemy and enemy.has_method("change_pose"):
                enemy.change_pose("neutral")
        else:
            if portrait_handler:
                portrait_handler.hide_portrait()
            if enemy and enemy.has_method("change_pose"):
                enemy.change_pose(tone)
    else:
        if portrait_handler:
            portrait_handler.hide_portrait()

func _play_blip(line):
    """Plays a short sound for each visible character printed."""
    # Do not play blip for spaces or punctuation
    var txt = line["text"] if line is Dictionary else String(line)
    if txt[char_index - 1] in [" ", "!", ".", ",", "?", "\n"]:
        return
    var speaker = "default"
    if line is Dictionary:
        speaker = line.get("speaker", "default").to_lower()
    var stream = blip_sounds.get(speaker, blip_sounds["default"])
    if stream:
        audio_player.stream = stream
        audio_player.play()

func _end_dialogue():
    """Hides the dialogue box and notifies listeners."""
    if portrait_handler:
        portrait_handler.hide_portrait()
    if enemy and enemy.has_method("change_pose"):
        enemy.change_pose("neutral")
    box.hide()
    active = false
    emit_signal("dialogue_finished")

# End of DialogueManager.gd
