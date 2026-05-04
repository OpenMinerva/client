extends CharacterBody3D

var speed = 5.0

@onready var hud = get_tree().current_scene.get_node("Hud")
@onready var scene_m = get_tree().current_scene.get_node("SceneManager")

# TODO: Mouse sensitivity from settings
# TODO: Replace interaction ray
# TODO: Add skeleton controller
# TODO: Mouse captured from HUD, not player controller
# TODO: Rotate climbing collider as you move WASD

@onready var body = $"."
@onready var head = $Head
@onready var camera = $Head/Camera3D
@export var mouse_sensitivity: float = 1.5

const base_fov = 90.0
const fov_change = 1.1

# Player speed
const SPRINT_SPEED = 6.0
const WALK_SPEED = 3.0
const CROUCH_SPEED = 1.5
const PRONE_SPEED = 0.5

const JUMP_VELOCITY = 4.5
const SENSITIVITY = 1.5

# Player statuses
var mouse_captured: bool = false

# Get the gravity from the project settings to be synced with RigidBody nodes.
var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")

func _enter_tree():
	set_multiplayer_authority(0)

func _ready():
	camera.fov = base_fov
	camera.current = false

func _input(event):
	if is_multiplayer_authority() == false:
		return

	if event is InputEventMouseMotion && mouse_captured:
		body.rotate_y(-event.relative.x * mouse_sensitivity * 0.001)
		camera.rotate_x(-event.relative.y * mouse_sensitivity * 0.001)
		camera.rotation.x = clamp(camera.rotation.x, deg_to_rad(-85), deg_to_rad(89))

func _unhandled_input(event):
	if is_multiplayer_authority() == false:
		return

	if event.is_action_pressed("escape"):
		if mouse_captured:
			capture_mouse(false)
			Events.emit_signal("dash_set_state", true)
		else:
			capture_mouse(true)
			Events.emit_signal("dash_set_state", false)

		get_viewport().set_input_as_handled()

func _physics_process(delta):
	# TODO: Simplify focus detection code from "mouse_captured".
	if is_multiplayer_authority() == false:
		return
	# Add the gravity.

	if not is_on_floor():
		velocity.y -= gravity * delta + 0.05

	if Input.is_action_pressed("sprint") && mouse_captured == true:
		speed = lerp(speed, SPRINT_SPEED, delta * 7.0)
		var pos = Vector3.ZERO
		pos.y = 1.7
		pos.z = -0.15
	else:
		speed = lerp(speed, WALK_SPEED, delta * 7.0)
		var pos = Vector3.ZERO
		pos.y = 1.7
		pos.z = -0.15
		head.transform.origin = lerp(head.transform.origin, pos, delta * 7.0)

	if !is_on_floor():
		speed = speed / 1.1

	# Get the input direction and handle the movement/deceleration.
	var input_dir: Vector2 = Vector2(0, 0)

	if mouse_captured == true:
		input_dir = Input.get_vector("left", "right", "forward", "backward")

	var direction = (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	if direction:
		velocity.x = direction.x * speed
		velocity.z = direction.z * speed
	else:
		velocity.x = lerp(velocity.x, direction.x * speed, delta * 20.0)
		velocity.z = lerp(velocity.z, direction.z * speed, delta * 20.0)

	if Input.is_action_just_pressed("jump") && is_on_floor() && mouse_captured == true:
		velocity.y = JUMP_VELOCITY

	move_and_slide()
	_send_player_synchronization_info()

func round_to_dec(num, digit):
	return round(num * pow(10.0, digit)) / pow(10.0, digit)

func get_subscene_root(node: Node) -> Node:
	var current_node = node
	if current_node.get_parent() != null:
		return current_node
	else:
		return null

func capture_mouse(to_capture: bool):
	if to_capture == false:
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
		mouse_captured = false
	else:
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
		mouse_captured = true
	return

func _send_player_synchronization_info():
	if is_multiplayer_authority() == false:
		return

	var compressed_position = NetworkCompression.c_16_pos(position)
	var compressed_rotation = NetworkCompression.c_16_vec3(rotation)

	# HACK: We are just appending the rotation bits at the end here. It should probably be more efficient somewhere else.
	compressed_position.append_array(compressed_rotation)

	scene_m.get_master_scene(scene_m.active_session).get_node("NetworkManager").entity_position.rpc(int(name), compressed_position)
