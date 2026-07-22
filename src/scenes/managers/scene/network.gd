extends Node

var _specific_api: SceneMultiplayer = null
var _my_id = 0
var _server_id: String = ""

@onready var player_m = get_node("../PlayerManager")
@onready var spawnable_m = get_node("../SpawnableManager")
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


@rpc("any_peer", "unreliable")
func entity_position(entity_id: int, position):
	var caller_id = multiplayer.get_remote_sender_id()
	if caller_id != entity_id:
		return
	var target_node = get_parent().get_node("root").get_node_or_null(str(entity_id))
	if target_node:
		target_node.position = NetworkCompression.d_16_pos(position)
		target_node.rotation = NetworkCompression.d_16_vec3(position.slice(12))


@rpc("any_peer", "reliable")
func dev_request_spawnables_database() -> void:
	var caller_id = multiplayer.get_remote_sender_id()

	# FIXME: We should not need to send the database_id, the host should tell the client what the id of a node is!
	GlobalLogger.log("Sending spawnable database to peer %d: %d entries, DB_ID: %d" % [caller_id, spawnable_m._database.size(), spawnable_m._database_id])
	spawnable_m.receive_database.rpc_id(caller_id, spawnable_m._database, spawnable_m._database_id, player_m.players)
	return

# FIXME Old dev function. Should be refactored!
@rpc("any_peer", "reliable")
func dev_request_sync() -> void:
	if is_multiplayer_authority() == false:
		return
	spawnable_m.sync_all()
	return


func gizmo_selection(node_id: int, to_select: bool) -> void:
	return


func _on_connected_to_server():
	# When the client is connected to the server, request the database from the server.
	GlobalLogger.log("[%s] I am connected to a server." % _my_id)

	# Request the spawnable database from host
	rpc_id(1, "dev_request_spawnables_database")


func _on_server_disconnected():
	network_m.leave_server(_server_id)
	return


func _on_peer_connected(peer_id: int):
	if is_multiplayer_authority() == false:
		return

	GlobalLogger.log("Peer '%s' is connected! Creating a player controller." % [peer_id])

	# Add player to the database.
	player_m.add_player(peer_id)
	player_m.add_player.rpc(peer_id)

	# Spawn the player controller.
	var _entity = await spawnable_m.create("OM_PlayerController")

	# Set the player node in the player database.
	player_m.set_player_node(peer_id, _entity)

	# The host adds a listener for the on_delete, then spawns the player back in.
	_entity.connect("tree_exiting", _on_peer_player_node_destroyed.bind(peer_id))

	GlobalLogger.log("[%s] Peer '%s' connected to our server." % [_my_id, peer_id])

	rpc_id(peer_id, "set_root", Enum.BaseLevel.GRID)
	# FIXME: There are now two functions that do this. Refactor one of them out. The newer one has better player node syncing.
	rpc_id(peer_id, "add_players", player_m.players)
	return


func _on_peer_disconnected(peer_id: int) -> void:
	if is_multiplayer_authority() == false:
		return

	player_m.remove_player(peer_id)
	player_m.remove_player.rpc(peer_id)

	GlobalLogger.log("[%s] Peer '%s' disconnected to our server." % [_my_id, peer_id])
	return

func _on_peer_player_node_destroyed(peer_id: int) -> void:
	GlobalLogger.log("Peer '%s' was destroyed! Queued a player controller respawn." % [peer_id])
	var _timer = get_tree().create_timer(1)

	_timer.timeout.connect(func () -> void:
		if player_m.players.keys().has(peer_id) == false:
			# Check to see if player still exists in the database, don't spawn if they are gone.
			GlobalLogger.log("Peer '%s' was disconnected, not respawning a player controller." % [peer_id])
			return

		var _entity = await spawnable_m.create("OM_PlayerController")
		spawnable_m.set_authority.rpc(int(_entity.name), peer_id)
		player_m.set_player_node(peer_id, _entity)
		_entity.connect("tree_exiting", _on_peer_player_node_destroyed.bind(peer_id))
	)

	return
