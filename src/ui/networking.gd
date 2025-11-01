extends Node

# TODO: Create helper function for status object
@onready var NetworkStatus = {
	"server": false,
	"client": false,
	"host":  "",
	"port": 0,
	"max_clients": 16
}

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

	_add_player(1)

	NetworkStatus.host = "127.0.0.1"
	NetworkStatus.port = port
	NetworkStatus.client = false
	NetworkStatus.server = true
	NetworkStatus.max_clients = max_clients

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

func _on_connected_to_server() -> void:
	var local_id = peer.get_unique_id()
	_add_player(local_id)

func _add_player(id: int) -> void:
	var player : Node3D = player_scene.instantiate()
	player.name = str(id)
	player.set_multiplayer_authority(id)
	add_child(player)

func _on_peer_connected(id: int) -> void:
	_add_player(id)

func _on_peer_disconnected(id: int) -> void:
	rpc_id(id, "_del_player", id)
	_remove_player(id)

func exit_game(id: int) -> void:
	rpc_id(id, "_del_player", id)
	_remove_player(id)

func _remove_player(id: int) -> void:
	var node = get_node_or_null(str(id))
	if node:
		node.queue_free()

@rpc("any_peer", "call_local")
func _del_player(id: int) -> void:
	_remove_player(id)

func increase_server_max_clients(new_max: int) -> void:
	pass

func _remove_all_players() -> void:
	for child in get_children():
		if child is Node3D and child.name.is_valid_int():
			child.queue_free()
