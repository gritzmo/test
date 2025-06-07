extends Node
class_name EnemyAI

"""
Simple helper node that lets you script enemy behavior by turn number.
Attach it as a child of an Enemy and fill `scripted_turns` with
dictionaries describing dialogue, buffs and which attack to use.
"""

# Dictionary mapping turn numbers to scripted actions.
# Example: {1: {"dialogue": "You're late!", "attack": "Warning Shot"}}
var scripted_turns := {}   # e.g. {1: {"dialogue": "Hi", "attack": "Punch"}}
var default_pattern := []  # Fallback list of attack names
var pattern_index := 0

func choose_attack(turn_number:int) -> String:
    """Returns the name of the attack to use this turn.
    May yield if dialogue is played before the attack."""
    var script = scripted_turns.get(turn_number, null)
    if script:
        if script.has("dialogue"):
            DialogueManager.start_dialogue([
                {"text": script.dialogue, "speaker": get_parent().name}
            ])
            await DialogueManager.dialogue_finished
        if script.has("buff") and get_parent().has_method("apply_buff"):
            get_parent().apply_buff(script.buff)
        if script.has("debuff_player") and get_parent().has_method("apply_debuff_to_player"):
            get_parent().apply_debuff_to_player(script.debuff_player)
        if script.has("attack"):
            return script.attack

    if default_pattern.size() > 0:
        var attack_name = default_pattern[pattern_index % default_pattern.size()]
        pattern_index += 1
        return attack_name

    # Return empty string if nothing is defined
    return ""
