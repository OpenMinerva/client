extends Node

@onready var scene_manager = get_tree().current_scene.get_node("SceneManager")
var n_c = preload("res://scripts/network_compression.gd").new()
var active_session: String = ""

func _ready():
	return

@rpc("authority", "reliable")
func spawn_player(id: int):
	var player_scene: PackedScene = load("res://scenes/players/player.tscn")
	GlobalLogger.logs("Spawning player %s" % id)
	var new_player = player_scene.instantiate()
	new_player.name = str(id)
	new_player.position = Vector3(0, 0, 0)
	scene_manager.get_current_session_node().call_deferred("add_child", new_player)

@rpc("any_peer", "reliable")
func player_position(info: PackedByteArray):
	var target_node = scene_manager.get_current_session_node().get_node_or_null(str(multiplayer.get_remote_sender_id()))

	if target_node == null:
		return

	# HACK: The rotation data is hacked on here. This needs to be addressed at some point.
	target_node.position = n_c.d_16_pos(info)
	target_node.rotation = n_c.d_16_vec3(info.slice(12))
	return
