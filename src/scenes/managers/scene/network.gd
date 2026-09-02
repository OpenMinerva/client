extends Node

var _specific_api: SceneMultiplayer = null
var _my_id: int = 0
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
	GlobalLogger.log("Setting up connection to '%s'" % id)
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


@rpc("any_peer", "reliable")
func req_spawnable_db() -> void:
	# A peer wants the server database.
	var caller_id = multiplayer.get_remote_sender_id()
	var _database: Array[Dictionary] = spawnable_m._registry.get_all_spawnable()
	var _assets: Array[Dictionary] = spawnable_m._registry.get_all_asset()
	var _asset_relations: Array[Dictionary] = spawnable_m._registry.get_all_asset_relation()

	GlobalLogger.log("Sending spawnable database to peer %d: %d entries" % [caller_id, _database.size()])

	# Send the spawnable and player database to the client.
	rec_spawnable_db.rpc_id(caller_id, _database, player_m.players, _assets, _asset_relations)

	return


@rpc("authority", "reliable")
func rec_spawnable_db(db: Array, players: Dictionary, assets: Array, asset_relations: Array) -> void:
	GlobalLogger.log("Received the spawnable database.")
	# We have the database, set it.
	await spawnable_m.receive_database(db, players, assets, asset_relations)

	# Tell the server we have finished spawning the nodes, tell the server to sync the transforms.
	spawnable_m.sync_all.rpc_id(1)

	return


func _on_connected_to_server():
	# When the client is connected to the server, request the database from the server.
	GlobalLogger.log("[%s] Connected to a server." % _my_id)

	# Set the scene root to empty.
	scene_m.set_master_root_from_program(_server_id, Enum.BaseLevel.EMPTY, "", false)

	# Request the spawnable database from host
	req_spawnable_db.rpc_id(1)


func _on_server_disconnected():
	GlobalLogger.log("Disconnected from '%s'" % _server_id)
	network_m.leave_server(_server_id)
	return


func _on_peer_connected(peer_id: int):
	if is_multiplayer_authority() == false:
		# Only the host runs the function.
		return

	GlobalLogger.log("Peer '%s' is connected! Creating a player controller." % [peer_id])

	# Add player to the database.
	player_m.add_player.rpc(peer_id)

	# Spawn the player controller.
	var _entity = await spawnable_m.create_spawnable("OM_PlayerController")

	# Set the player node in the player database.
	player_m.set_player_node.rpc(peer_id, int(_entity.name))

	# The host adds a listener for the on_delete, then spawns the player back in.
	_entity.connect("tree_exiting", _on_peer_player_node_destroyed.bind(peer_id))

	GlobalLogger.log("[%s] Peer '%s' connected to our server." % [_my_id, peer_id])

	return


func _on_peer_disconnected(peer_id: int) -> void:
	if is_multiplayer_authority() == false:
		return

	GlobalLogger.log("[%s] Peer '%s' disconnected to our server." % [_my_id, peer_id])

	player_m.remove_player.rpc(peer_id)

	return


func _on_peer_player_node_destroyed(peer_id: int) -> void:
	if is_multiplayer_authority() == false:
		return

	GlobalLogger.log("Peer '%s' was destroyed! Queued a player controller respawn." % [peer_id])

	var _timer = get_tree().create_timer(1)

	_timer.timeout.connect(
		func() -> void:
			if player_m.players.keys().has(str(peer_id)) == false:
				# Check to see if player still exists in the database, don't spawn if they are gone.
				GlobalLogger.log("Peer '%s' was disconnected, not respawning a player controller." % [peer_id])
				return

			var _entity = await spawnable_m.create("OM_PlayerController")
			spawnable_m.set_authority.rpc(int(_entity.name), peer_id)
			player_m.set_player_node.rpc(peer_id, int(_entity.name))
			_entity.connect("tree_exiting", _on_peer_player_node_destroyed.bind(peer_id))
	)

	return
