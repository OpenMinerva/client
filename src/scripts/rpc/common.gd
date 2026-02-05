extends Node

var n_c = preload("res://scripts/network/network_compression.gd").new()
@onready var network_manager = get_tree().current_scene.get_node("NetworkManager")

@rpc("any_peer", "unreliable")
func on_player_transform(info):
	# TODO: Authenticate
	var target_node = network_manager.player_exists(str(multiplayer.get_remote_sender_id()))

	if target_node == null:
		return

	# HACK: The rotation data is hacked on here. This needs to be addressed at some point.
	target_node.position = n_c.d_16_pos(info)
	target_node.rotation = n_c.d_16_vec3(info.slice(12))
	return


@rpc("any_peer", "unreliable")
func on_node_transform() -> void:
	# Handles changing positions of a node.
	# This should only be used when a node is moving, and not to position a node on spawn.
	# TODO: Authenticate
	return

@rpc("authority", "reliable")
func on_spawn_player(id) -> void:
	var player_scene: PackedScene = load("res://scenes/players/player.tscn")
	GlobalLogger.logs("Spawning player %s" % id)
	var new_player = player_scene.instantiate()
	new_player.name = str(id)
	new_player.position = Vector3(0, 0, 0)
	network_manager.spawn_player(new_player)
	return

@rpc("authority", "reliable")
func on_spawn_node() -> void:
	return
