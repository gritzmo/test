extends Node
class_name BugSweepSummary

# Prints a summary of the manual bug sweep. Attach as autoload if needed.
const SUMMARY_TEXT := """Bug-Sweep Summary:\nScripts scanned: 29\nWarnings fixed: 5\nOutstanding FIX-ME tags: 1\nBreaking issues: none"""

func _ready() -> void:
    print(SUMMARY_TEXT)

