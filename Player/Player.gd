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
var is_dashing = false
var is_crouching = false
var is_jumping_down = false
var is_ladder_climbing = false
var ladder_idle = false
var ledge_grabbing = false
var oneway_grabbing = false
var roll_time = 0
var direction = Vector2.ZERO
var flip = null

var timer = null

func _ready():
	animation_player = $"AnimationPlayer"
	sensors = $"Sensors"
	
	timer = Timer.new()
	timer.connect("timeout", Callable(self, "ready_to_stop_jump_down"))
	timer.wait_time = .2
	timer.one_shot = true
	add_child(timer)

func _physics_process(delta):
	process_animation()
	
	# Get the input direction and handle the movement/deceleration.
	# As good practice, you should replace UI actions with custom gameplay actions.
	if not ledge_grabbing or not is_ladder_climbing:
		direction = Vector2( Input.get_axis("mv_left", "mv_right"), Input.get_axis("jmp","down")*-1 )
	
	process_jump_down(delta)
	process_ladder_climbing(delta)
	
	# Add the gravity.
	if not is_on_floor():
		if not is_jumping_down and not is_ladder_climbing:
			if is_on_wall() and not direction.x == 0:
				velocity.y = 20
			else:
				velocity.y += gravity * delta
	else:
		if direction.y < 0 and not is_jumping_down and not is_ladder_climbing:
			is_crouching = true
			return
		else:
			is_crouching = false
		jump = 0

	# Handle Jump.
	if Input.is_action_just_pressed("jmp"):
		is_ladder_climbing = false
		if jump < MAX_JUMP and not is_rolling:
			velocity.y = JUMP_VELOCITY
			jump += 1
	
	# Handle Roll.
	if Input.is_action_just_pressed("roll"):
		if not is_rolling or not is_dashing:
			if is_on_floor() or is_ladder_climbing:
				is_rolling = true
			else:
				is_dashing = true
		is_ladder_climbing = false
	
	process_oneway_grabbing(delta)
	process_ledge_grabbing(delta)
	process_rolling(delta)
	move_and_slide()
	
	var new_speed = SPEED if not is_rolling else ROLL_SPEED
	if direction:
		if not is_ladder_climbing:
			velocity.x = direction.x * new_speed
		else:
			velocity.x = 0
		flip = direction.x
	else:
		velocity.x = move_toward(velocity.x, 0, new_speed)

func done_ladder_climbing():
	is_ladder_climbing = false

func process_ladder_climbing(_delta):
	if ledge_grabbing or is_jumping_down or is_jumping_down or oneway_grabbing:
		done_ladder_climbing()
		return
	if not is_ladder_climbing and $"Sensors/LadderSensor".has_overlapping_bodies() and not direction.y == 0:
		overlapping_body = $"Sensors/LadderSensor".get_overlapping_bodies()[0]
		position.x = overlapping_body.getX()
		if direction.y < 0:
			translate(Vector2(0, 110))
		is_ladder_climbing = true
	
	if is_ladder_climbing:
		if not $"Sensors/LadderSensor".has_overlapping_bodies():
			done_ladder_climbing()
		if Input.is_action_pressed("jmp"):
			ladder_idle = false
			velocity.y = -100
		elif Input.is_action_pressed("down"):
			ladder_idle = false
			velocity.y = 100
		else:
			ladder_idle = true
			velocity.y = 0

func done_ledge_climbing(x, y):
	ledge_grabbing = false
	#translate(Vector2(16*flip,-66))
	var y_snap = int(32 * (position.y + y) / 32)
	position.x = position.x + x*flip
	position.y = y_snap
	#translate(Vector2(x*flip,y_snap))
	add_child(sensors)
	overlapping_body.disable(false)

func done_oneway_climbing(x, y):
	oneway_grabbing = false
	var y_snap = int(32 * (position.y + y) / 32)
	position.x = position.x + x*flip
	position.y = y_snap
	#translate(Vector2(x*flip,y_snap))
	add_child(sensors)
	overlapping_body.disable(false)

var overlapping_body = null

func process_oneway_grabbing(_delta):
	if ledge_grabbing or is_jumping_down or is_jumping_down:
		return
	if not oneway_grabbing and $"Sensors/OnewaySensor".has_overlapping_bodies():
		translate(Vector2(0, -30))
		oneway_grabbing = true
		overlapping_body = $"Sensors/OnewaySensor".get_overlapping_bodies()[0]
		overlapping_body.disable(true)
		remove_child(sensors)
	
	if oneway_grabbing:
		velocity = Vector2.ZERO

func process_ledge_grabbing(_delta):
	if oneway_grabbing or is_jumping_down or is_jumping_down:
		return
	if not ledge_grabbing and $"Sensors/GrabSensorOn".has_overlapping_bodies() and not $"Sensors/GrabSensorOff".has_overlapping_bodies() and not is_rolling:
		ledge_grabbing = true
		overlapping_body = $"Sensors/GrabSensorOn".get_overlapping_bodies()[0]
		overlapping_body.disable(true)
		translate(Vector2(0,2))
		remove_child(sensors)
	
	if ledge_grabbing:
		velocity = Vector2.ZERO

func process_rolling(_delta):
	if oneway_grabbing or is_jumping_down or is_jumping_down:
		is_rolling = false
		is_dashing = false
		return
		
	if is_rolling or is_dashing:
		if not is_on_floor() and is_dashing:
			velocity.y = 0
		ledge_grabbing = false
		direction.x = transform.x.x
		roll_time += _delta
		var sensor_overlaps = $"Sensors/RollSensor".has_overlapping_bodies()
		if roll_time > MAX_ROLL_TIME and not sensor_overlaps:
			is_rolling = false
			is_dashing = false
			roll_time = 0

var _ready_to_stop_jump_down = false

func ready_to_stop_jump_down():
	_ready_to_stop_jump_down = true
	$"CollisionShape2D".disabled = false

func process_jump_down(_delta):
	if not is_jumping_down and direction.y < 0 and is_on_floor() and Input.is_action_just_pressed("roll") and $"Sensors/JumpDownSensor".has_overlapping_bodies():
		is_jumping_down = true
		_ready_to_stop_jump_down = false
		$"CollisionShape2D".disabled = true
		#translate(Vector2(0,32))
		remove_child(sensors)
		timer.start()
		
	if is_jumping_down:
		#translate(Vector2(0,10))
		velocity.y += (gravity*5) * _delta
		if _ready_to_stop_jump_down and is_on_floor():
			is_jumping_down = false
			add_child(sensors)

func process_animation():
	if not direction.x == 0:
		transform.x.x = direction.x
	
	if is_ladder_climbing:
		if ladder_idle:
			animation_player.play("ladderidle_animation")
		else:
			animation_player.play("ladderclimb_animation")
	elif is_jumping_down:
		animation_player.play("fall_animation")
	elif is_crouching:
		animation_player.play("crouch_animation")
	elif is_rolling:
		animation_player.play("roll_animation")
	elif is_dashing:
		animation_player.play("dash_animation")
	elif oneway_grabbing:
		animation_player.play("onewayclimb_animation")
	elif ledge_grabbing:
		animation_player.play("ledgeclimb_animation")
	elif velocity.y != 0:
		if velocity.y < 0:
			animation_player.play("jump_animation")
		else:
			if is_on_wall():
				animation_player.play("slide_animation")
			else:
				animation_player.play("fall_animation")
	elif velocity.x != 0:
		animation_player.play("run_animation")
	else:
		animation_player.play("idle_animation")
