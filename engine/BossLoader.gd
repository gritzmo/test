extends Node
class_name BossLoader

"""Loads boss data and related assets from a folder."""

const Utils = preload("res://engine/util/safe_load.gd")

func load_boss(folder:String) -> Dictionary:
    """Returns a dictionary with boss info and preloaded assets."""
    var base = "res://content/bosses/%s/" % folder
    var data:Dictionary = {}
    var boss_res = Utils.safe_load(base + "boss.tres")
    if boss_res:
        data = boss_res.duplicate(true)
    # Load pose textures
    data.poses = {}
    for k in boss_res.poses.keys():
        var path = boss_res.poses[k]
        data.poses[k] = Utils.safe_load(path)
    # Load attack resources
    data.attacks = []
    for a in boss_res.attacks:
        var att = Utils.safe_load(a)
        if att:
            data.attacks.append(att)
    data.folder = folder
    return data

