extends CharacterBody3D

## The speed at which the player moves.
const BASE_SPEED = 5.0
## The speed modifier when the player is sprinting.
const SPRINT_MODIFIER = 1.5
## The speed at which the player moves when sprinting.
const SPRINT_SPEED = BASE_SPEED * SPRINT_MODIFIER
## The velocity at which the player jumps.
const JUMP_VELOCITY = 4.0
## The control factor for the player's motion on the ground. Higher value = more control.
const GROUND_CONTROL = 20.0
## The control factor for the player's motion in the air.
const JUMP_CONTROL = 4.0

## The sensitivity of the mouse for looking around.
const VIEW_SENS = 0.003
## The bounds of the camera's vertical view in degrees.
const VIEW_BOUNDS = [-80, 80]

## The base FOV of the camera, used when the player is stopped.
const BASE_FOV = 60.0
## The FOV of the camera at max speed.
const MAX_FOV = 100.0
## FOV does not keep rising once speed is above this factor.
const MAX_FOV_SPEED = SPRINT_SPEED * 2
## The rate of change for the camera's FOV.
const FOV_RATE = 8.0

## How frequently the headbob should occur.
const HEADBOB_FREQ = 2.0
## The vertical and horizontal amplitude of the headbob.
const HEADBOB_AMP = [0.08, 0.12]

# Get the gravity from the project settings to be synced with RigidBody nodes.
var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")

## Time along the headbob curve.
var headbob_t = 0.0

## The head of the player.
@onready var head: Node3D = $Head
## The camera for the player's view.
@onready var camera: Node3D = $Head/Camera3D


func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)


func _unhandled_input(event: InputEvent):
	if event is InputEventMouseMotion:
		head.rotate_y(-event.relative.x * VIEW_SENS)
		camera.rotate_x(-event.relative.y * VIEW_SENS)
		camera.rotation.x = clamp(
			camera.rotation.x, deg_to_rad(VIEW_BOUNDS[0]), deg_to_rad(VIEW_BOUNDS[1])
		)


func _physics_process(delta: float):
	var v := velocity.length()

	if not is_on_floor():
		velocity.y -= gravity * delta

	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = JUMP_VELOCITY

	var sprint := 1.0
	if Input.is_action_pressed("sprint"):
		sprint = SPRINT_MODIFIER

	var input_dir := Input.get_vector("left", "right", "up", "down")
	var direction := (head.transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	var goal_x := direction.x * BASE_SPEED * sprint
	var goal_z := direction.z * BASE_SPEED * sprint
	var control := GROUND_CONTROL if is_on_floor() else JUMP_CONTROL
	velocity.x = lerp(velocity.x, goal_x, control * delta)
	velocity.z = lerp(velocity.z, goal_z, control * delta)

	headbob_t += delta * velocity.length() * float(is_on_floor())
	camera.transform.origin = headbob(headbob_t)

	camera.fov = lerp(camera.fov, target_fov(v), delta * FOV_RATE)

	move_and_slide()


## A vector representing the head bobbing motion at a given point in time.
func headbob(t: float) -> Vector3:
	var p := Vector3.ZERO
	p.y = HEADBOB_AMP[0] * sin(t * HEADBOB_FREQ)
	p.x = HEADBOB_AMP[1] * cos(t * HEADBOB_FREQ * 0.5)
	return p


## The target FOV for a given velocity.
func target_fov(v: float) -> float:
	# Normalize velocity from (BASE_SPEED, MAX_FOV_SPEED) to (0, 1)
	var fov_v1 = clamp(v - BASE_SPEED, 0, MAX_FOV_SPEED - BASE_SPEED) / (MAX_FOV_SPEED - BASE_SPEED)
	return lerp(BASE_FOV, MAX_FOV, fov_v1)
