extends Node

var c := preload("res://scripts/rpc/client.gd").new()
var s := preload("res://scripts/rpc/server.gd").new()
var com := preload("res://scripts/rpc/common.gd").new()

func _ready():
	# RPCs can not be called from outside of the scene tree, we are required to add them.
	add_child(c)
	add_child(s)
	add_child(com)
	
	multiplayer.peer_connected.connect(s.on_peer_connected)
	multiplayer.peer_disconnected.connect(s.on_peer_disconnected)
	multiplayer.connected_to_server.connect(c.connected_to_server)
	multiplayer.connection_failed.connect(c.connection_failed)