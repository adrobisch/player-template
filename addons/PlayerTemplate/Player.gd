extends CharacterBody3D
class_name Player

## character speed factor
@export var speed = 5.0

## character jump velocity
@export var jump_velocity = 6.0
## the distance of the camera, will set the spring length
@export var camera_distance = 3
## pause toggle, will stop input and physics processing
@export var paused = false

## camera max angle
@export var camera_max_angle = 60
## camera min angle
@export var camera_min_angle = -20

## camera acceleration
@export var camera_acceleration = 20
## horizontal camera sensitivity
@export var h_sensitivity = 0.005
## vertical camera sensitivity
@export var v_sensitivity = 0.005

## movement smoothness
@export var movement_smoothness = 0.1

@export var left_action = "ui_left"
@export var right_action = "ui_right"
@export var up_action = "ui_up"
@export var down_action = "ui_down"
@export var jump_action = "ui_accept"

## path the a node the will recieve the rotation of this 
@export_node_path("Node3D") var remote_transform_path: NodePath

@onready var cam_root: SpringArm3D = $Head/SpringArm3D
@onready var remote_transform: RemoteTransform3D =  $Head/SpringArm3D/RemoteTransform3D

## current camera rotation input values
var camrot_h = 0
var camrot_v = 0

## max camera angles
var cam_v_max = deg_to_rad(camera_max_angle)
var cam_v_min = deg_to_rad(camera_min_angle)

# Get the gravity from the project settings to be synced with RigidBody nodes.
var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")

func _ready():
	cam_root.spring_length = camera_distance
	if remote_transform_path:
		# get absolute path
		var path = get_node(remote_transform_path).get_path()
		remote_transform.remote_path = path

func _unhandled_input(event):
	if paused:
		return
	
	if event is InputEventMouseMotion:
		camrot_h += -event.relative.x * h_sensitivity
		camrot_v += event.relative.y * v_sensitivity
		camrot_v = clamp(camrot_v, cam_v_min, cam_v_max)

func update_camera(delta):
	cam_root.rotation.y = lerp_angle(cam_root.rotation.y, camrot_h, delta * camera_acceleration)
	cam_root.rotation.x = lerp_angle(cam_root.rotation.x, -camrot_v, delta * camera_acceleration)
	
func _physics_process(delta):
	if paused:
		return
	
	update_camera(delta)
	
	# Add the gravity.
	if not is_on_floor():
		velocity.y -= gravity * delta

	# Handle jump.
	if Input.is_action_just_pressed(jump_action) and is_on_floor():
		velocity.y = jump_velocity

	# Get the input direction and handle the movement/deceleration.
	# As good practice, you should replace UI actions with custom gameplay actions.
	var input_dir = Input.get_vector(left_action, right_action, up_action, down_action)
	var direction = (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	# move into camera direction
	direction = direction.rotated(Vector3.UP, cam_root.rotation.y)
	
	if direction:
		velocity.x = direction.x * speed
		velocity.z = direction.z * speed
	else:
		velocity.x = move_toward(velocity.x, 0, speed)
		velocity.z = move_toward(velocity.z, 0, speed)

	move_and_slide()
