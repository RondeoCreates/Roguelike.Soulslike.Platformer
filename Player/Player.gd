extends CharacterBody2D


@export var SPEED = 150.0
@export var ROLL_SPEED = 300.0
@export var JUMP_VELOCITY = -400.0
@export var MAX_JUMP = 2
@export var MAX_ROLL_TIME = .5

# Get the gravity from the project settings to be synced with RigidBody nodes.
var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")
var animated_sprite = null
var collision_shape = null
var roll_shape = null
var jump = 0
var is_rolling = false
var ledge_grabbing = false
var roll_time = 0
var direction = null

func _ready():
	animated_sprite = $"AnimatedSprite2D"
	collision_shape = $"CollisionShape2D"
	roll_shape =  $"RollCollision"

func _physics_process(delta):
	# Add the gravity.
	if not is_on_floor():
		velocity.y += gravity * delta
	else:
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

	# Get the input direction and handle the movement/deceleration.
	# As good practice, you should replace UI actions with custom gameplay actions.
	if not ledge_grabbing:
		direction = Input.get_axis("mv_left", "mv_right")

	process_ledge_grabbing(delta)
	move_and_slide()
	process_rolling(delta)
	process_animation()
	
	var new_speed = SPEED if not is_rolling else ROLL_SPEED
	if direction:
		velocity.x = direction * new_speed
	else:
		velocity.x = move_toward(velocity.x, 0, new_speed)

func reset_height():
	collision_shape.disabled = false
	roll_shape.disabled = true
	
func done_ledge_climbing():
	translate(Vector2(16*(1 if direction > 0 else -1),-64))
	ledge_grabbing = false

func process_ledge_grabbing(delta):
	if not ledge_grabbing and $"GrabSensorOn".has_overlapping_bodies() and not $"GrabSensorOff".has_overlapping_bodies() and not is_rolling:
		ledge_grabbing = true
	
	if ledge_grabbing:
		velocity.y = 0
		if animated_sprite.frame >= 6:
			done_ledge_climbing()

func process_rolling(delta):
	if is_rolling:
		if not is_on_floor():
			velocity.y = 0
		ledge_grabbing = false
		direction = -1 if animated_sprite.flip_h else 1
		roll_time += delta
		collision_shape.disabled = true
		roll_shape.disabled = false
		#if animated_sprite.animation_finished:
		var sensor_overlaps = $"RollSensor".has_overlapping_bodies()
		if roll_time > MAX_ROLL_TIME and not sensor_overlaps:
			is_rolling = false
			roll_time = 0
	else:
		reset_height()
		

func process_animation():
	if velocity.x < 0:
		animated_sprite.flip_h = true
	elif velocity.x > 0:
		animated_sprite.flip_h = false
	
	if is_rolling:
		if not is_on_floor():
			animated_sprite.play("Dash")
		else:
			animated_sprite.play("Roll")
	elif ledge_grabbing:
		animated_sprite.play("Climb_Up")
	elif velocity.y != 0:
		if velocity.y < 0:
			animated_sprite.play("Jump_Up")
		else:
			animated_sprite.play("Jump_Down")
	elif velocity.x != 0:
		animated_sprite.play("Run")
	else:
		animated_sprite.play("Idle")
