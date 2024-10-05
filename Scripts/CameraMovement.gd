extends Node3D

@export var acceleration: float = 25.0
@export var move_speed: float = 5.0
@export var sensibility: float = 300.0

var velocity: Vector3 = Vector3.ZERO
var look_angles: Vector2 = Vector2.ZERO

func _input(event: InputEvent) -> void:
	if get_viewport().use_xr == false:
		if Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
			if event is InputEventMouseMotion:
				look_angles -= event.relative / sensibility

func _process(delta: float) -> void:
	look_angles.y = clamp(look_angles.y, PI / -2, PI / 2)
	rotation = Vector3(look_angles.y, look_angles.x, 0)
	
	# Handle mouse mode #
	if Input.is_action_pressed("camera_control"):
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	else:
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	
	# Handle camera movement #
	var direction = _handle_direction()
	if direction == Vector3.ZERO:
		velocity = lerp(velocity, Vector3.ZERO, delta * 6)
	if direction.length_squared() > 0:
		velocity = lerp(velocity, velocity + direction * acceleration * delta, delta * 10)
	if velocity.length() > move_speed:
		velocity = velocity.normalized() * move_speed
	
	translate(velocity * delta)

func _handle_direction() -> Vector3:
	var direction = Vector3.ZERO
	
	if Input.is_action_pressed("forward"):
		direction += Vector3.FORWARD
	if Input.is_action_pressed("back"):
		direction += Vector3.BACK
	if Input.is_action_pressed("left"):
		direction += Vector3.LEFT
	if Input.is_action_pressed("right"):
		direction += Vector3.RIGHT
	if Input.is_action_pressed("up"):
		direction += Vector3.UP
	if Input.is_action_pressed("down"):
		direction += Vector3.DOWN
	
	return direction.normalized()
