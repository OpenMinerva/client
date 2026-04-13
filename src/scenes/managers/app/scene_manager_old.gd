extends Node

# TODO: Allow multiple sessions
# Right now only one session is allowed and is destroyed when the player joins another session.

# Game managers
@onready var network_manager = get_tree().current_scene.get_node("NetworkManager")
@onready var scene_work_root = get_tree().current_scene.get_node("Scenes")
@onready var player_home_scene: PackedScene = load("res://scenes/levels/home.tscn")

var server_init: bool = false

func _ready():
	await network_manager.start_server(20205, 2)

func load_multiplayer_scene(scene_dir: String, scene_name: String):
	await _clean_scene_work_root()
	var scene_packed: PackedScene = load(scene_dir)

	var scene = scene_packed.instantiate()
	scene.name = scene_name
	scene_work_root.add_child(scene)
	await get_tree().process_frame
	return

func _clean_scene_work_root():
	var nodes_to_destroy = scene_work_root.get_children()
	for node in nodes_to_destroy:
		node.queue_free()
	await get_tree().process_frame
	return

func _spawn_host_player():
	network_manager.spawn_player(1)

func get_current_session_node():
	return get_tree().current_scene.get_node("Scenes").get_child(0)
