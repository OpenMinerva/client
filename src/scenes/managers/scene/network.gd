extends Node

var _specific_api: SceneMultiplayer = null
var _my_id = 0

func setup_connection(api: SceneMultiplayer):
	_specific_api = api
	_specific_api.connected_to_server.connect(_on_connected_to_server)
	_my_id = multiplayer.get_unique_id()

func _on_connected_to_server():
	GlobalLogger.logs("[%s] I am connected to a server." % _my_id)
	rpc_id(1, "_rpc_hello")

@rpc("any_peer", "unreliable")
func _rpc_hello():
	var caller_id = multiplayer.get_remote_sender_id()
	GlobalLogger.logs("[%s] Hello from '%s'." % [_my_id, caller_id])
	rpc_id(caller_id, "_on_hello_world_received")

@rpc("authority", "unreliable")
func _on_hello_world_received():
	GlobalLogger.logs("[%s] Server replied." % [_my_id])

func _process(_delta):
	if multiplayer:
		multiplayer.poll()
