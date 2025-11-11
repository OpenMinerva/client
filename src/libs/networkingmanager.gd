extends AwaitableHTTPRequest
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
	"session_id": null,
	"session_name": null,
	"session_description": "",
	"session_key": "",
	"session_max_clients": 0,
	"session_join_privacy": "",
	"session_ip": "",
	"session_port": 0,
	"users": {}
}
@onready var _clients : Dictionary = {}

var world_scene : PackedScene = preload("res://environments/PlayerHome.tscn")
var world_instance : Node3D
var _advertise_server_timer: SceneTreeTimer = null

var peer := ENetMultiplayerPeer.new()

@export var player_scene : PackedScene = preload("res://players/PlayerController.tscn")

func _ready() -> void:
	multiplayer.peer_disconnected.connect(_on_peer_disconnected)

func create_server(port: int = 5996, max_clients: int = 16) -> void:
	var err = peer.create_server(port, max_clients)
	# TODO: Handle port conflicts
	if err != OK:
		LoggerManager.log_string("Failed to start server on port %d: %s" % [port, str(err)], 3)
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

	var args = LaunchManager.get_command_line_args()

	_clients = {"1": {
		"name": args.get("name", "NOT_SET"),
		"moderator": true,
		"admin": true,
	}}

	advertise_server()
	start_advertising_server()

func join_server(host: String, port: int = 5996) -> void:
	_remove_all_players()

	peer = ENetMultiplayerPeer.new()
	var err = peer.create_client(host, port)
	if err != OK:
		LoggerManager.log_string("Failed to connect to %s:%d: %s" % [host, port, str(err)], 3)
		return

	multiplayer.multiplayer_peer = peer
	multiplayer.peer_connected.connect(_on_peer_connected)
	multiplayer.connected_to_server.connect(_on_connected_to_server)

	NetworkStatus.host = host
	NetworkStatus.port = port
	NetworkStatus.client = true
	NetworkStatus.server = false
	# TODO: Max clients

func _verify_info(info: Dictionary) -> bool:
	# TODO: Verify client info
	# This is placeholder function for actual validation
	LoggerManager.log_string("Verifying client info: %s" %info, 1)
	# Is account banned (IP address / Account ID / Prism ID)
	# Is account anonymous (Does server allow anonymous players)
	# Is account blocked by host
	return true

func _on_connected_to_server() -> void:
	var local_id = peer.get_unique_id()
	var args = LaunchManager.get_command_line_args()

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
	LoggerManager.log_string("Peer attempting connection: %d" %id, 1)
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
		LoggerManager.log_string("Validation failed for peer %d" % peer_id, 1)
		multiplayer.disconnect_peer(peer_id)

@rpc("any_peer", "call_local")
func request_session_list() -> void:
	rpc("session_list", _clients)

@rpc("any_peer", "call_local")
func client_approved() -> void:
	LoggerManager.log_string("Client approved by server", 1)
	# NetworkStatus.client_approved = true

@rpc("authority", "call_local")
func session_list(clients: Dictionary) -> void:
	LoggerManager.log_string("Received client list: %s" % clients, 1)
	ServerInfo.users = clients
	emit_signal("clients_updated")

@rpc("any_peer", "call_local")
func kick_player(id: int, reason: String) -> void:
	LoggerManager.log_string("Trying to kick player %d for reason: %s" % [id, reason], 1)
	if not NetworkStatus.server:
		# Not the server, we don't care.
		return

	var caller_id = multiplayer.get_remote_sender_id()

	if not _clients[str(caller_id)].moderator:
		LoggerManager.log_string("User %s tried to kick without permission" % _clients[str(caller_id)].name, 1)
		return

	if id == 1:
		LoggerManager.log_string("Cannot kick server", 1)
		return

	multiplayer.disconnect_peer(id)
	_on_peer_disconnected(id)

func request_kick(id: int, reason: String) -> void:
	LoggerManager.log_string("Requesting kick for player %d for reason: \"%s\"" % [id, reason], 1)
	rpc_id(1, "kick_player", id, reason)

# TODO: Ban players

func start_advertising_server() -> void:
	stop_advertising_server()
	_advertise_server_timer = get_tree().create_timer(30, false, false, true)
	_advertise_server_timer.timeout.connect(advertise_server)

func stop_advertising_server() -> void:
	if _advertise_server_timer == null:
		return
	_advertise_server_timer.timeout.disconnect(advertise_server)
	_advertise_server_timer = null

func advertise_server() -> void:
	# TODO: Separate server creation with updating / heartbeating
	# When server is created, print that the server is created, otherwise print that the server was updated
	if NetworkStatus.server:
		LoggerManager.log_string("Trying to advertise the server", 0)
		var advertisement_response
		var need_to_create_session : bool = ServerInfo.session_id == null

		if need_to_create_session:
			LoggerManager.log_string("Registering server", 1)
			advertisement_response = await async_request("http://localhost:5000/api/sessions", [], HTTPClient.Method.METHOD_POST)
			LoggerManager.log_string(advertisement_response.body_as_string(), 0)
			ServerInfo.session_id = advertisement_response.body_as_json().sessionId
		else:
			LoggerManager.log_string("Updating server", 1)
			var http_url = "http://localhost:5000/api/sessions/%s" % ServerInfo.session_id
			advertisement_response = await async_request(http_url, [], HTTPClient.Method.METHOD_POST)
			LoggerManager.log_string(advertisement_response.body_as_string(), 0)

		if advertisement_response.success() and advertisement_response.status_ok():
			LoggerManager.log_string("Successfully advertised with id: \"%s\"" % advertisement_response.body_as_json().sessionId, 0)

		# TODO: Handle when server can not contact session-manager server
		# TODO: Handle when server validation fails
	start_advertising_server()

func get_servers_from_session_server() -> Array:
	var http_url = "http://localhost:5000/api/sessions"
	var response = await async_request(http_url, [], HTTPClient.Method.METHOD_GET)
	if response.success() and response.status_ok():
		return response.body_as_json().sessions
	return []
