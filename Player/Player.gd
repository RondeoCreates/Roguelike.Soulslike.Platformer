extends CharacterBody2D


@export var SPEED = 150.0
@export var ROLL_SPEED = 300.0
@export var JUMP_VELOCITY = -400.0
@export var MAX_JUMP = 2
@export var MAX_ROLL_TIME = .5

# Get the gravity from the project settings to be synced with RigidBody nodes.
var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")
var animation_player = null
var sensors = null
var roll_shape = null
var jump = 0
var is_rolling = false
var is_crouching = false
var ledge_grabbing = false
var roll_time = 0
var direction = Vector2.ZERO
var flip = null;

func _ready():
	animation_player = $"AnimationPlayer"
	sensors = $"Sensors"

func _physics_process(delta):
	process_animation()
	
	# Get the input direction and handle the movement/deceleration.
	# As good practice, you should replace UI actions with custom gameplay actions.
	if not ledge_grabbing:
		direction = Vector2( Input.get_axis("mv_left", "mv_right"), Input.get_axis("jmp","down")*-1 )
	
	# Add the gravity.
	if not is_on_floor():
		velocity.y += gravity * delta
	else:
		if direction.y < 0:
			is_crouching = true
			return
		else:
			is_crouching = false
		jump = 0

	# Handle Jump.
	if Input.is_action_just_pressed("jmp"):
		if jump < MAX_JUMP:
			velocity.y = JUMP_VELOCITY
			jump += 1
	
	# Handle Roll.
	if Input.is_action_just_pressed("roll"):
		if not is_rolling:
			is_rolling = true

	process_ledge_grabbing(delta)
	move_and_slide()
	process_rolling(delta)
	
	var new_speed = SPEED if not is_rolling else ROLL_SPEED
	if direction:
		velocity.x = direction.x * new_speed
		flip = direction.x
	else:
		velocity.x = move_toward(velocity.x, 0, new_speed)

func done_ledge_climbing(x, y):
	ledge_grabbing = false
	#translate(Vector2(16*flip,-66))
	var y_snap = int(32 * (position.y + y) / 32)
	position.x = position.x + x*flip
	position.y = y_snap
	#translate(Vector2(x*flip,y_snap))
	add_child(sensors)
	overlapping_body.disable(false)

var overlapping_body = null

func process_ledge_grabbing(delta):
	if not ledge_grabbing and $"Sensors/GrabSensorOn".has_overlapping_bodies() and not $"Sensors/GrabSensorOff".has_overlapping_bodies() and not is_rolling:
		ledge_grabbing = true
		overlapping_body = $"Sensors/GrabSensorOn".get_overlapping_bodies()[0]
		overlapping_body.disable(true)
		translate(Vector2(0,2))
		remove_child(sensors)
	
	if ledge_grabbing:
		velocity = Vector2.ZERO

func process_rolling(delta):
	if is_rolling:
		if not is_on_floor():
			velocity.y = 0
		ledge_grabbing = false
		direction.x = transform.x.x
		roll_time += delta
		var sensor_overlaps = $"Sensors/RollSensor".has_overlapping_bodies()
		if roll_time > MAX_ROLL_TIME and not sensor_overlaps:
			is_rolling = false
			roll_time = 0

func process_animation():
	if not direction.x == 0:
		transform.x.x = direction.x
	
	if is_crouching:
		animation_player.play("crouch_animation")
	elif is_rolling:
		animation_player.play("roll_animation")
		#if not is_on_floor():
			#animation_player.play("dash_animation")
		#else:
			#animation_player.play("roll_animation")
	elif ledge_grabbing:
		animation_player.play("ledgeclimb_animation")
	elif velocity.y != 0:
		if velocity.y < 0:
			animation_player.play("jump_animation")
		else:
			animation_player.play("fall_animation")
	elif velocity.x != 0:
		animation_player.play("run_animation")
	else:
		animation_player.play("idle_animation")
