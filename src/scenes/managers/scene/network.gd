extends Node

var _specific_api: SceneMultiplayer = null
var _my_id = 0
var _server_id: String = ""

@onready var player_m = get_node("../PlayerManager")
@onready var scene_m = get_tree().current_scene.get_node("SceneManager")
@onready var network_m = get_tree().current_scene.get_node("NetworkManager")


func _process(_delta):
	if multiplayer:
		multiplayer.poll()
		return


func setup_connection(api: SceneMultiplayer, id: String):
	_specific_api = api
	_server_id = id

	_specific_api.connected_to_server.connect(_on_connected_to_server)
	_specific_api.peer_connected.connect(_on_peer_connected)
	_specific_api.peer_disconnected.connect(_on_peer_disconnected)
	_specific_api.server_disconnected.connect(_on_server_disconnected)

	_my_id = multiplayer.get_unique_id()


@rpc("authority", "unreliable")
func ban_player():
	GlobalLogger.log("'%s' is not implemented." % get_stack()[0]["function"], Enum.LogLevel.WARNING)
	return


func on_kicked():
	GlobalLogger.log("'%s' is not implemented." % get_stack()[0]["function"], Enum.LogLevel.WARNING)
	return


func on_banned():
	GlobalLogger.log("'%s' is not implemented." % get_stack()[0]["function"], Enum.LogLevel.WARNING)
	return


@rpc("authority", "reliable")
func set_root(scene_type: Enum.BaseLevel):
	GlobalLogger.log("[%s] Received root base scene." % [_my_id])
	scene_m.set_master_root_from_program(_server_id, scene_type)


@rpc("authority", "reliable")
func add_players(players: Dictionary):
	GlobalLogger.log("[%s] Playerlist received." % [_my_id])
	for _player in players.keys():
		player_m.add_player(int(_player))


@rpc("authority", "reliable")
func spawn_entity():
	GlobalLogger.log("'%s' is not implemented." % get_stack()[0]["function"], Enum.LogLevel.WARNING)


@rpc("any_peer", "unreliable")
func entity_position(entity_id: int, position):
	var caller_id = multiplayer.get_remote_sender_id()
	if caller_id != entity_id:
		return
	var target_node = get_parent().get_node("root").get_node_or_null(str(entity_id))
	if target_node:
		target_node.position = NetworkCompression.d_16_pos(position)
		target_node.rotation = NetworkCompression.d_16_vec3(position.slice(12))


func _on_connected_to_server():
	GlobalLogger.log("[%s] I am connected to a server." % _my_id)


func _on_server_disconnected():
	network_m.leave_server(_server_id)
	return


func _on_peer_connected(peer_id: int):
	if is_multiplayer_authority() == false:
		return

	player_m.add_player(peer_id)
	player_m.add_player.rpc(peer_id)

	GlobalLogger.log("[%s] Peer '%s' connected to our server." % [_my_id, peer_id])
	rpc_id(peer_id, "set_root", Enum.BaseLevel.GRID)
	rpc_id(peer_id, "add_players", player_m.players)
	return


func _on_peer_disconnected(peer_id: int) -> void:
	if is_multiplayer_authority() == false:
		return

	player_m.remove_player(peer_id)
	player_m.remove_player.rpc(peer_id)

	GlobalLogger.log("[%s] Peer '%s' disconnected to our server." % [_my_id, peer_id])
	return
