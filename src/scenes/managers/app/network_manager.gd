extends Node

var n_c = preload("res://scripts/network_compression.gd").new()
var jwt = preload("res://scripts/crypto/jwt.gd").new()
var rsa = preload("res://scripts/crypto/rsa.gd").new()
var url_regex = RegEx.create_from_string("^(https?)://([^/:]+)(?::(\\d+))?(.*)$")

# TODO: Bandwidth toggles
@onready var scene_manager = get_tree().current_scene.get_node("SceneManager")
@onready var multiplayer_manager = get_tree().current_scene.get_node("MultiplayerManager")

# This file contains all of the session management and client communication.
# Anything that goes through the network should first route through here at some point.
enum server_privacy {PRIVATE, INVITE, FRIENDS, PUBLIC}

var status = {
	"hosting": false,
	"client": false
}

var config = {
	"port": 20205,
	"max_clients": 4,
	"privacy": 0,

	"networking": {
		"use_steam": false,
		"use_lan": false
	}
}

var info = {
	"level": "res://scenes/levels/home.tscn",
	"level_node_name": "",
	"clients": []
}

func _ready():
	multiplayer.peer_connected.connect(_on_peer_connected)
	multiplayer.peer_disconnected.connect(_on_peer_disconnected)

	multiplayer.connected_to_server.connect(_on_connected)
	multiplayer.connection_failed.connect(_on_connection_failed)

func start_server(port: int = config.port, max_clients: int = config.max_clients) -> void:
	if status.hosting:
		# This ideally should not trigger
		GlobalLogger.logs("Can not start server: Server is already running.", 2)
		status.hosting = false
		status.client = false
		return

	var new_peer = ENetMultiplayerPeer.new()
	# FIXME: Error handling is required here
	var err = new_peer.create_server(port, max_clients)
	# FIXME: This client append is happening too early, this is a debug position
	info.clients.append({"display_name": "Me!", "multiplayer_id": 1})
	if err != OK:
		GlobalLogger.logs("Failed to start server.", 3)
		status.hosting = false
		status.client = false
		return

	multiplayer.multiplayer_peer = new_peer
	GlobalLogger.logs("Successfully started server.", 1)

	while status.hosting == false:
		await get_tree().process_frame
		status.hosting = true
		status.client = false
	
func close_server():
	# Disconnect all players.
	# Remove listings from all used networking.
	# Update server config.
	# TODO: OfflineMultiplayerPeer is a test. Check to see if this actually works.
	multiplayer.multiplayer_peer = OfflineMultiplayerPeer.new()
	status.hosting = false
	status.client = false

	return

func update_server():
	# Update our config.
	# Submit a update to any active networking service.
	return

func join_server(ip: String = "", port: int = config.port) -> void:
	# Client connects to a server.
	if ip.is_empty():
		GlobalLogger.logs("No IP to connect to.", 2)
		return
	
	if status.hosting:
		# This ideally should not trigger
		GlobalLogger.logs("Can not join server: We are currently hosting a server.", 2)
		return
	
	var new_peer = ENetMultiplayerPeer.new()
	new_peer.create_client(ip, port)
	multiplayer.multiplayer_peer = new_peer

	status.hosting = false
	status.client = true
	GlobalLogger.logs("Connected to the server.", 1)
	return

func kick_player(player_id: int, reason: String = "No reason specified"):
	# Server kicks a player from the session.
	return

func ban_player():
	# Server permanatly bans a user.
	return

func _on_connected():
	# We are connected to the server.
	GlobalLogger.logs("Connected to the server as '%s'." % multiplayer.get_unique_id(), 1)
	return

func _on_connection_failed():
	GlobalLogger.logs("Connection to server failed.", 1)
	return

func _on_peer_connected(client_id):
	info.level_node_name = get_tree().current_scene.get_node("Scenes").get_child(0).name

	# A client has been connected to our server.
	if multiplayer.is_server() == false:
		return

	# TODO: Preform validation to determine if the player is allowed to be here

	GlobalLogger.logs("'%s' connected to us. Sending our server info." % multiplayer.get_unique_id(), 1)
	_receive_server_info.rpc_id(client_id, info)

	return

func _on_peer_disconnected():
	return

func set_networking_config(options: Dictionary) -> void:
	if !options:
		GlobalLogger.logs("Tried to set networking config without options", 2)
		return
	
	# LAN connections
	if options.lan == true:
		config.use_lan = true
	else:
		config.use_lan = false

	# Steam connections
	if options.steam == true:
		config.use_steam = true
	else:
		config.use_steam = false

@rpc("authority", "reliable")
func _receive_server_info(server_info: Dictionary):
	GlobalLogger.logs("Received server information.")
	# TODO: Do not change scene until connection is finalized.

	if server_info.level:
		await scene_manager.load_multiplayer_scene(server_info.level, server_info.level_node_name)

	_send_player_info(CredentialStore.info.token)

@rpc("any_peer", "reliable")
func _receive_player_info(player_info: String):
	# TODO: Error checks for JWT
	if multiplayer.is_server() == false:
		# We are a client. We should not process any farther.
		return

	GlobalLogger.logs("Received '%s' player info." % multiplayer.get_remote_sender_id())
	
	# TODO: Preform validation to determine if the player is allowed to be here
	# TODO: Preform validation to determine if the player supplied cridentials are good, where they need to be.

	# Preform validation of JWT token
	var player_info_dic = _sanity_check_player_info(player_info, multiplayer.get_remote_sender_id())
	var player_decoded_jwt = jwt.decode(player_info_dic.jwt)

	# TODO: util function to break down a url to the key parts.
	var url_parts = parse_url(player_decoded_jwt.data.payload.issuer)
	var host_pub_key = await AccountServers._request_server_pem(url_parts.host, url_parts.port)

	var host_pub_key_cryptokey: CryptoKey = rsa.pem_to_cryptokey(host_pub_key)

	var jwt_is_valid = jwt.verify(player_info_dic.jwt, host_pub_key_cryptokey)

	if jwt_is_valid == false:
		# TODO: Refuse connection
		multiplayer.multiplayer_peer.disconnect_peer(multiplayer.get_remote_sender_id())
		return

	info.clients.append(player_info_dic)
	
	# Spawn player
	multiplayer_manager.spawn_player(player_info_dic.multiplayer_id)
	multiplayer_manager.rpc("spawn_player", player_info_dic.multiplayer_id)

	# Spawn all connected clients on the new client
	for client in info.clients:
		if client.multiplayer_id == player_info_dic.multiplayer_id:
			continue
		multiplayer_manager.rpc_id(player_info_dic.multiplayer_id, "spawn_player", client.multiplayer_id)

	send_server_session_info()
	
func _send_player_info(player_info: String):
	GlobalLogger.logs("Starting server handshake: Sending information about ourself.")
	_receive_player_info.rpc_id(1, player_info)

func send_server_session_info() -> void:
	rpc("received_server_session_info", info)

@rpc("authority", "reliable")
func received_server_session_info(received_info: Dictionary) -> void:
	GlobalLogger.logs("Session information updated.")
	info = received_info
	return

# TODO: Handle kick from server
# TODO: Handle ban from server
# TODO: Add item to player inventory
# TODO: Remove item from player inventory
# TODO: Check if item exists in player inventory
# TODO: Get player inventory

func _sanity_check_player_info(player_info: String, multiplayer_id: int) -> Dictionary:
	var sane_player_info = {
		"jwt": "",
		"multiplayer_id": "",
		"display_name": "Greetings!"
	}

	sane_player_info.jwt = str(player_info)
	sane_player_info.multiplayer_id = int(multiplayer_id)

	return sane_player_info


func parse_url(url: String) -> Dictionary:
	var result = {
		"scheme": "",
		"host": "",
		"port": 0,
		"path": ""
	}

	var matches = url_regex.search(url)
	if matches:
		result["scheme"] = matches.get_string(1).to_lower()
		result["host"] = matches.get_string(2)
		result["port"] = int(matches.get_string(3)) if matches.get_string(3) != "" else (443 if result["scheme"] == "https" else 80)
		result["path"] = matches.get_string(4) if matches.get_string(4) != "" else "/"

	return result
