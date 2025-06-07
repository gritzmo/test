extends Node
class_name Utils

"""Utility functions shared across High Kick Hell scripts."""

static func safe_load(path:String, fallback=null):
    """Safely loads a resource from disk.
    Returns the loaded resource or the fallback if the file is missing.
    Logs a warning when the file cannot be loaded."""
    # SAFETY: File may be missing
    var res = ResourceLoader.load(path)
    if res == null:
        push_warning("Missing file: %s" % path)
        return fallback
    return res


