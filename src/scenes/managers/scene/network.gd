extends Node

var _specific_api: SceneMultiplayer = null
var _my_id = 0
var _server_id: String = ""

@onready var player_m = get_parent().get_node("PlayerManager")
@onready var scene_m = get_tree().current_scene.get_node("SceneManager")
@onready var network_m = get_tree().current_scene.get_node("NetworkManager")
var n_c = preload("res://scripts/network/network_compression.gd").new()

func _process(_delta):
	if multiplayer:
		multiplayer.poll()

func setup_connection(api: SceneMultiplayer, id: String):
	_specific_api = api
	_server_id = id

	_specific_api.connected_to_server.connect(_on_connected_to_server)
	_specific_api.peer_connected.connect(_on_peer_connected)

	_my_id = multiplayer.get_unique_id()

func _on_connected_to_server():
	GlobalLogger.logs("[%s] I am connected to a server." % _my_id)
	# rpc_id(1, "player_spawn_request")

# @rpc("any_peer", "unreliable")
# func player_spawn_request():
# 	if is_multiplayer_authority() == false:
# 		return
# 	var caller_id = multiplayer.get_remote_sender_id()
# 	GlobalLogger.logs("[%s] Player spawn request from '%s'." % [_my_id, caller_id])
# 	player_m.spawn_player.rpc(caller_id)

@rpc("authority", "unreliable")
func kick_player():
	GlobalLogger.logs("'%s' is not implemented." % get_stack()[0]["function"], 3)
	return

@rpc("authority", "unreliable")
func ban_player():
	GlobalLogger.logs("'%s' is not implemented." % get_stack()[0]["function"], 3)
	return

func on_kicked():
	GlobalLogger.logs("'%s' is not implemented." % get_stack()[0]["function"], 3)
	return

func on_banned():
	GlobalLogger.logs("'%s' is not implemented." % get_stack()[0]["function"], 3)
	return

func _on_peer_connected(peer_id: int):
	# player_m.add_player.rpc()
	# rpc("player_m.add_player", peer_id)
	# rpc("player_m.spawn_player", _player)
	# rpc(peer_id, "set_root", Enum.BaseLevel.GRID)
	if is_multiplayer_authority() == false:
		return
		
	player_m.add_player.rpc(str(peer_id))
	player_m.spawn_player.rpc(str(peer_id))

	GlobalLogger.logs("[%s] Peer '%s' connected to our server." % [_my_id, peer_id])
	rpc_id(peer_id, "set_root", Enum.BaseLevel.GRID)
	rpc_id(peer_id, "add_players", player_m.players)
	# rpc_id(peer_id, "set_server_id", _server_id)
	return

@rpc("authority", "reliable")
func set_root(scene_type: Enum.BaseLevel):
	GlobalLogger.logs("[%s] Received root base scene." % [_my_id])
	scene_m.set_master_root_from_program(_server_id, scene_type)

# @rpc("authority", "reliable")
# func set_server_id(server_id: String):
# 	GlobalLogger.logs("[%s] Received server ID." % [_my_id])
# 	_server_id = server_id
# 	get_parent().name = server_id

@rpc("authority", "reliable")
func add_players(players: Array):
	GlobalLogger.logs("[%s] Playerlist received." % [_my_id])
	for _player in players:
		player_m.spawn_player(str(_player))

@rpc("authority", "reliable")
func spawn_entity():
	var caller_id = multiplayer.get_remote_sender_id()
	GlobalLogger.logs("[%s] Entity received '%s'." % [_my_id, caller_id])
	player_m.spawn_player(str(caller_id))

@rpc("any_peer", "unreliable")
func entity_position(entity_id: int, entity_position):
	var caller_id = multiplayer.get_remote_sender_id()
	if caller_id != entity_id:
		return
	# if is_multiplayer_authority() == true:
	# 	GlobalLogger.logs("[%s] [%s] Entity '%s' position received from '%s'." % [_my_id, get_parent().name, entity_id, caller_id])
	var target_node = get_parent().get_node("root").get_node_or_null(str(entity_id))
	if target_node:
		# print(target_node.name)
		target_node.position = n_c.d_16_pos(entity_position)
		target_node.rotation = n_c.d_16_vec3(entity_position.slice(12))
