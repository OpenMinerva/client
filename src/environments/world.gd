extends Node3D

func _ready():
	Networking.create_server(5996, 2)
	pass
