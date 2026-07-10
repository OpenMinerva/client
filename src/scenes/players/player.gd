# --- License
# File: /client/src/scenes/players/player.gd
# Project: OpenMinerva
# Created Date: 04 July 2026
# Copyright (c) 2026 OpenMinerva
# License: MIT License
# Authors: Armored Dragon
# --- License
extends CharacterBody3D

# FIXME: Multiplayer CEM camera:
	# When one player activates CEM camera, all players spawn the camera?
	# Size not networked.
	# Position not networked.

# Libraries
@onready var _app_scene_m: Node = get_tree().current_scene.get_node("SceneManager")
@onready var _session_spawnable_m: Node

# Nodes
@onready var _node_head = get_node("Head")
@onready var _node_body = get_node(".")
@onready var _node_camera = get_node("Head/Camera3D")
@onready var _node_cem_camera: Node3D = null

# Constants
const _DEFAULT_FOV: float = 90.0
const _DEFAULT_JUMP_VELOCITY: float = 4.5
const _DEFAULT_SENSITIVITY: float = 1.5
const _DEFAULT_GRAVITY: float = 9.81
const _DEFAULT_SPRINT_SPEED: float = 6.0
const _DEFAULT_SPEED: float = 3.0
const _DEFAULT_CROUCH_SPEED: float = 1.5

# States
var _cem_state: bool = false
var _cem_camera: bool = false
var _dash_state: bool = false

var _cem_panning: bool = false
var _cem_rotating: bool = false

var _scene_root: Node3D

# Variables
var _speed: float = 0
var _mouse_captured: bool = false

func _enter_tree() -> void:
	set_multiplayer_authority(0)

	# FIXME: Properly get the session spawnable node.
	_session_spawnable_m = get_parent().get_parent().get_node("SpawnableManager")
	return

func _ready() -> void:
	_node_camera.fov = _DEFAULT_FOV

	Events.connect("dash_set_state", _handle_dash_state)
	return

func _physics_process(delta) -> void:
	if is_multiplayer_authority() == false:
		return

	_phys_buildmode(delta)
	_phys_normal(delta)

	return

func _phys_buildmode(delta) -> void:
	if _cem_camera == false:
		return

	var _input_dir = Input.get_vector("left", "right", "forward", "backward")
	var _local_direction = Vector3(_input_dir.x, 0, _input_dir.y)

	if Input.is_action_just_pressed("cem_camera_pan"):
		_cem_panning = true
		return

	if Input.is_action_just_released("cem_camera_pan"):
		_cem_panning = false
		return

	if Input.is_action_just_pressed("cem_camera_rotate"):
		_cem_rotating = true
		Events.emit_signal("cem_camera_rotating", true)
		StateManager.update_mouse_state()
		return

	if Input.is_action_just_released("cem_camera_rotate"):
		Events.emit_signal("cem_camera_rotating", false)
		_cem_rotating = false
		StateManager.update_mouse_state()
		return

	if _node_cem_camera != null:
		_node_cem_camera.translate(Vector3(_local_direction.x * 0.1, 0, _local_direction.z * 0.1))

		var _transform = _node_cem_camera.transform
		_session_spawnable_m.set_transform(int(_node_cem_camera.name), _transform)
	return

func _phys_normal(delta) -> void:
	if is_on_floor() == false:
		velocity.y -= _DEFAULT_GRAVITY * delta

	if StateManager.is_mouse_captured() == false:
		velocity.x = 0
		velocity.z = 0

		move_and_slide()
		_send_player_position()
		return

	_speed = _DEFAULT_SPEED
	if Input.is_action_pressed("sprint"):
		_speed = _DEFAULT_SPRINT_SPEED

	if _cem_camera == false:
		var _input_dir = Input.get_vector("left", "right", "forward", "backward")
		var _direction = (transform.basis * Vector3(_input_dir.x, 0, _input_dir.y)).normalized()
		velocity.x = _direction.x * _speed
		velocity.z = _direction.z * _speed

	if Input.is_action_pressed("jump") && is_on_floor():
		velocity.y = _DEFAULT_JUMP_VELOCITY

	move_and_slide()
	_send_player_position()
	return

func _input(event) -> void:
	if is_multiplayer_authority() == false:
		return

	if StateManager.is_mouse_captured() && event is InputEventMouseMotion:
		if _cem_camera == false:
			_node_body.rotate_y(-event.relative.x * _DEFAULT_SENSITIVITY * 0.001)
			_node_camera.rotate_x(-event.relative.y * _DEFAULT_SENSITIVITY * 0.001)
			_node_camera.rotation.x = clamp(_node_camera.rotation.x, deg_to_rad(-85), deg_to_rad(89))

		if _cem_camera == true && _node_cem_camera != null:
			if _cem_panning == true:
				_node_cem_camera.translate(Vector3(event.relative.x * 0.01, -event.relative.y * 0.01, 0))

				# Network position:
				var _transform = _node_cem_camera.transform
				_session_spawnable_m.set_transform(int(_node_cem_camera.name), _transform)

			_node_cem_camera.rotation.y -= event.relative.x * _DEFAULT_SENSITIVITY * 0.001
			_node_cem_camera.rotation.x = clampf(_node_cem_camera.rotation.x - event.relative.y * _DEFAULT_SENSITIVITY * 0.001, deg_to_rad(-89), deg_to_rad(89))

	return

func _send_player_position() -> void:
	if is_multiplayer_authority() == false:
		return

	var compressed_position = NetworkCompression.c_16_pos(position)
	var compressed_rotation = NetworkCompression.c_16_vec3(rotation)

	# HACK: We are just appending the rotation bits at the end here. It should probably be more efficient somewhere else.
	compressed_position.append_array(compressed_rotation)

	_app_scene_m.get_master_scene(_app_scene_m.active_session).get_node("NetworkManager").entity_position.rpc(int(name), compressed_position)

	return

func _handle_dash_state(state: bool) -> void:
	_dash_state = state
	return

func _cem_camera_state(state: bool) -> void:
	_scene_root = _app_scene_m.get_master_root(_app_scene_m.active_session)
	_cem_camera = state

	if _cem_camera == true:
		_node_cem_camera = await _cem_camera_build()
		var _player_pos = position

		_node_camera.current = false
		# FIXME: Improper camera get.
		_node_cem_camera.get_child(0).current = true

		_node_cem_camera.position = Vector3(_player_pos.x + 2, _player_pos.y + 2, _player_pos.z + 2)
		_session_spawnable_m.set_transform(int(_node_cem_camera.name), _node_cem_camera.transform)

		_node_cem_camera.look_at(_node_body.global_position)
		return

	if _node_cem_camera != null:
	# FIXME: Improper camera get.
	# TODO: Add error if this code is ran without _node_cem_camera defined.
		_node_cem_camera.get_child(0).current = false
		await _session_spawnable_m.destroy(int(_node_cem_camera.name))
	_node_camera.current = true

	return

func _cem_camera_build() -> Node3D:
	var _nsb_empty_index: int = NSB.get_node_index("Node3D")
	var _nsb_camera_index: int = NSB.get_node_index("CEM_Camera")
	var _nsb_mesh_index: int = NSB.get_node_index("Box")

	var _node_root = await _session_spawnable_m.create(_nsb_empty_index)
	var _node_camera = await _session_spawnable_m.create(_nsb_camera_index, int(_node_root.name))
	var _node_model = await _session_spawnable_m.create(_nsb_mesh_index, int(_node_root.name))

	return _node_root

func _cem_camera_lookat(node: Node) -> void:
	_node_camera.look_at(node)
	return
