extends CharacterBody3D

const SPEED = 5.0
const JUMP_VELOCITY = 4.5
const SENSITIVITY = 0.01
var GRAVITY = ProjectSettings.get_setting("physics/3d/default_gravity")


@onready var head = $Head
@onready var camera = $Head/Camera3D
@onready var vrheadset = $Head/Camera3D/VRHeadset

func _enter_tree():
	set_multiplayer_authority(name.to_int())

func _ready():
	if not is_multiplayer_authority():
			camera.current = false
			return

	camera.set_multiplayer_authority(-1)
	camera.current = true

	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	for mi in vrheadset.find_children("*", "MeshInstance3D", true, false):
		mi.set_layer_mask(10)
	camera.cull_mask &= ~10

func _unhandled_input(event):
	if not is_multiplayer_authority():
		return
	if event is InputEventMouseMotion:
		rotate_y(-event.relative.x * SENSITIVITY)
		camera.rotate_x(-event.relative.y * SENSITIVITY)
		camera.rotation.x = clamp(camera.rotation.x, deg_to_rad(-89), deg_to_rad(89))

func _physics_process(delta):
	if not is_multiplayer_authority():
			return
	if not is_on_floor():
		velocity.y -= GRAVITY * delta

	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = JUMP_VELOCITY
	var input_dir = Input.get_vector("left", "right", "forward", "backward")
	var direction = (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()

	if direction:
		velocity.x = direction.x * SPEED
		velocity.z = direction.z * SPEED
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)
		velocity.z = move_toward(velocity.z, 0, SPEED)

	move_and_slide()

func _input(event):
	if not is_multiplayer_authority():
			return
	if event is not InputEventKey:
		return
