extends CharacterBody3D

var speed = 5.0

@onready var multiplayer_manager = get_tree().current_scene.get_node("MultiplayerManager")
@onready var hud = get_tree().current_scene.get_node("Hud")

var n_c = preload("res://scripts/network_compression.gd").new()

@onready var body = $"."
@onready var head = $Head
@onready var camera = $Head/Camera3D
@onready var interaction_ray = $Head/Camera3D/InteractionRay
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

# TODO: Rotate climbing collider as you move WASD

# Get the gravity from the project settings to be synced with RigidBody nodes.
var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")

func _enter_tree():
	set_multiplayer_authority(name.to_int())
	
func _ready():
	camera.fov = base_fov
	camera.current = is_multiplayer_authority()

func _input(event):
	if is_multiplayer_authority() == false:
		return
	if Input.is_action_just_pressed("escape"):
		if mouse_captured:
			capture_mouse(false)
			hud.set_active_state(true)
		else:
			capture_mouse(true)
			hud.set_active_state(false)
		return

	if event is InputEventMouseMotion && mouse_captured:
		body.rotate_y(-event.relative.x * mouse_sensitivity * 0.001)
		camera.rotate_x(-event.relative.y * mouse_sensitivity * 0.001)
		camera.rotation.x = clamp(camera.rotation.x, deg_to_rad(-85), deg_to_rad(89))

func _physics_process(delta):
	if is_multiplayer_authority() == false:
		return
	# Add the gravity.
	check_if_interaction_ray_is_colliding()

	if not is_on_floor():
		velocity.y -= gravity * delta + 0.05

	if Input.is_action_pressed("sprint"):
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
	if mouse_captured == true:
		var input_dir = Input.get_vector("left", "right", "forward", "backward")
		var direction = (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
		if direction:
			velocity.x = direction.x * speed
			velocity.z = direction.z * speed
		else:
			velocity.x = lerp(velocity.x, direction.x * speed, delta * 20.0)
			velocity.z = lerp(velocity.z, direction.z * speed, delta * 20.0)
		
		var velocity_clamped = clamp(velocity.length(), 0.5, SPRINT_SPEED * 2)
		var target_fov = base_fov + fov_change * velocity_clamped
		camera.fov = lerp(camera.fov, target_fov, delta * 8.0)
			
		if Input.is_action_just_pressed("jump") and is_on_floor():
			velocity.y = JUMP_VELOCITY

	move_and_slide()
	_send_player_synchronization_info()
	
func round_to_dec(num, digit):
	return round(num * pow(10.0, digit)) / pow(10.0, digit)
	
# User interaction ray
func check_if_interaction_ray_is_colliding():
	if interaction_ray.is_colliding():
		var subscene_root = get_subscene_root(interaction_ray.get_collider());
		if subscene_root == null:
			return
		
		if !subscene_root.is_in_group("interactable"):
			return
		
		# Interact
		if Input.is_action_just_pressed("interact"):
			subscene_root.interact()

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
	
	var compressed_position = n_c.c_16_pos(position)
	var compressed_rotation = n_c.c_16_vec3(rotation)

	# HACK: We are just appending the rotation bits at the end here. It should probably be more efficient somewhere else.
	compressed_position.append_array(compressed_rotation)

	multiplayer_manager.rpc("player_position", compressed_position)