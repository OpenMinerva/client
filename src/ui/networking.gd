extends Node
signal clients_updated

# TODO: Implement SERVER user functionality
# TODO: Create helper function for status object
@onready var NetworkStatus = {
	"server": false,
	"client": false,
	# "client_approved": false,
	"host":  "",
	"port": 0,
	"max_clients": 16
}
@onready var ServerInfo = {
	"users": {}
}
@onready var _clients : Dictionary = {}

var world_scene : PackedScene = preload("res://environments/PlayerHome.tscn")
var world_instance : Node3D

var peer := ENetMultiplayerPeer.new()

@export var player_scene : PackedScene = preload("res://players/PlayerController.tscn")

func _ready() -> void:
	multiplayer.peer_disconnected.connect(_on_peer_disconnected)

func create_server(port: int = 5996, max_clients: int = 16) -> void:
	var err = peer.create_server(port, max_clients)
	# TODO: Handle port conflicts
	if err != OK:
		push_error("Failed to start server on port %d: %s" % [port, str(err)])
		port = port + 1
		peer.create_server(port, max_clients)

	multiplayer.multiplayer_peer = peer
	multiplayer.peer_connected.connect(_on_peer_connected)

	world_instance = world_scene.instantiate()
	world_instance.name = "World"
	get_tree().root.add_child(world_instance)

	_add_player(1)

	NetworkStatus.host = "127.0.0.1"
	NetworkStatus.port = port
	NetworkStatus.client = false
	NetworkStatus.server = true
	NetworkStatus.max_clients = max_clients

	var args = get_command_line_args()

	_clients = {"1": {
		"name": args.get("name", "NOT_SET"),
		"moderator": true,
		"admin": true,
	}}

func join_server(host: String, port: int = 5996) -> void:
	_remove_all_players()

	peer = ENetMultiplayerPeer.new()
	var err = peer.create_client(host, port)
	if err != OK:
		push_error("Failed to connect to %s:%d: %s" % [host, port, str(err)])
		return

	multiplayer.multiplayer_peer = peer
	multiplayer.peer_connected.connect(_on_peer_connected)
	multiplayer.connected_to_server.connect(_on_connected_to_server)

	NetworkStatus.host = host
	NetworkStatus.port = port
	NetworkStatus.client = true
	NetworkStatus.server = false
	# TODO: Max clients

func get_command_line_args() -> Dictionary:
	var arguments = {}
	for argument in OS.get_cmdline_args():
			if argument.contains("="):
				var key_value = argument.split("=")
				arguments[key_value[0].trim_prefix("--")] = key_value[1]
			else:
				# Options without an argument will be present in the dictionary,
				# with the value set to an empty string.
				arguments[argument.trim_prefix("--")] = ""
	return arguments

func _verify_info(info: Dictionary) -> bool:
	# TODO: Verify client info
	# This is placeholder function for actual validation
	print("Verifying client info:", info)
	return true

func _on_connected_to_server() -> void:
	var local_id = peer.get_unique_id()
	var args = get_command_line_args()

	var client_info = {
		"name": args.get("name", "Anonymous")
	}

	rpc_id(1, "validate_client_info", client_info)
	_add_player(local_id)

func _add_player(id: int) -> void:
	var player : Node3D = player_scene.instantiate()
	player.name = str(id)
	player.set_multiplayer_authority(id)
	add_child(player)

func _on_peer_connected(id: int) -> void:
	print("Peer attempting connection:", id)
	_add_player(id)

	if NetworkStatus.server:
		# Send the world to the client
		rpc_id(id, "receive_world", world_scene)

func _on_peer_disconnected(id: int) -> void:
	rpc_id(id, "_del_player", id)
	_remove_player(id)

func exit_game(id: int) -> void:
	rpc_id(id, "_del_player", id)
	_remove_player(id)

func _remove_player(id: int) -> void:
	_clients.erase(str(id))
	request_session_list()

	var node = get_node_or_null(str(id))
	if node:
		node.queue_free()

@rpc("any_peer", "call_local")
func _del_player(id: int) -> void:
	_remove_player(id)

func _remove_all_players() -> void:
	for child in get_children():
		if child is Node3D and child.name.is_valid_int():
			child.queue_free()

@rpc("any_peer", "call_local")
func receive_world(world_packed: PackedScene) -> void:
	# Client receives the packed scene, instantiates it, and adds it to the root.
	var world_node = world_packed.instantiate()
	world_node.name = "World"
	get_tree().root.add_child(world_node)

@rpc("any_peer")
func validate_client_info(info: Dictionary) -> void:
	# Only run on the server
	if not NetworkStatus.server:
		return

	var peer_id = multiplayer.get_remote_sender_id()
	print(info)

	if _verify_info(info):
		var client_dict = info.duplicate()
		client_dict["moderator"] = false
		client_dict["admin"] = false
		_clients[str(peer_id)] = client_dict

		rpc_id(peer_id, "client_approved")
		request_session_list()
	else:
		print("Validation failed for peer %d" % peer_id)
		multiplayer.disconnect_peer(peer_id)

@rpc("any_peer", "call_local")
func request_session_list() -> void:
	rpc("session_list", _clients)

@rpc("any_peer", "call_local")
func client_approved() -> void:
	print("Approved by server")
	# NetworkStatus.client_approved = true

@rpc("authority", "call_local")
func session_list(clients: Dictionary) -> void:
	print("Got clients: ", clients)
	ServerInfo.users = clients
	emit_signal("clients_updated")

@rpc("any_peer", "call_local")
func kick_player(id: int, reason: String) -> void:
	print("Trying to kick player %d for reason: %s" % [id, reason])
	if not NetworkStatus.server:
		# Not the server, we don't care.
		return

	var caller_id = multiplayer.get_remote_sender_id()

	if not _clients[str(caller_id)].moderator:
		print("User %s tried to kick without permission" % _clients[str(caller_id)].name)
		return

	multiplayer.disconnect_peer(id)
	_on_peer_disconnected(id)


func request_kick(id: int, reason: String) -> void:
	print("Requesting kick for player %d for reason: %s" % [id, reason])
	rpc_id(1, "kick_player", id, reason)
