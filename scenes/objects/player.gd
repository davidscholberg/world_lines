@tool
extends CharacterBody2D

signal player_completed_level

const arrow_max_distance: float = 200.0
const arrow_min_distance: float = 100.0
const arrow_scale_factor: float = 0.05
const arrow_scale_power_ratio_factor: float = 0.5
const arrow_height: float = 1024.0
const arrow_y_offset: float = -50
const initial_velocity_min: float = 100.0
const initial_velocity_max: float = 300.0

var radius: float = 20.0
var gravity_factor: float = 1000.0
var initial_velocity_factor: float
var in_motion: bool = false
var initial_position: Vector2
var destination_reached: bool = false
var distance_to_destination_center: float
var direction_to_destination_center: Vector2
var initial_destination_reached_position: Vector2
var completed_level: bool = false
var exploding: bool = false

func _setup_collision_shape() -> void:
	var circle_shape: CircleShape2D = CircleShape2D.new()
	circle_shape.radius = radius
	var shape_owner_id: int = create_shape_owner(self)
	shape_owner_add_shape(shape_owner_id, circle_shape)

func _calculate_power_ratio(player_position: Vector2, mouse_position: Vector2) -> float:
	var distance: float = player_position.distance_to(mouse_position)
	distance = clampf(distance, arrow_min_distance, arrow_max_distance)
	return absf((distance - arrow_min_distance) / (arrow_max_distance - arrow_min_distance))

func _calculate_arrow_scale_ratio(power_ratio: float) -> float:
	return arrow_scale_power_ratio_factor + ((1 - arrow_scale_power_ratio_factor) * power_ratio)

func _calculate_arrow_scale_y_offset(scale_y: float) -> float:
	# TODO: don't calculate this every frame
	var full_scaled_arrow_height: float = arrow_height * arrow_scale_factor
	var scaled_arrow_height: float = arrow_height * scale_y
	return (full_scaled_arrow_height - scaled_arrow_height) / 2

func _calculate_initial_velocity_factor(power_ratio: float) -> float:
	return initial_velocity_min + ((initial_velocity_max - initial_velocity_min) * power_ratio)

func _setup_bounds_check() -> void:
	for boundary in get_tree().get_nodes_in_group("boundaries"):
		boundary.body_entered.connect(_out_of_bounds)

func _out_of_bounds(_body: Node2D) -> void:
	_setup_player()

func _setup_destination_collision_check() -> void:
	for destination in get_tree().get_nodes_in_group("destination"):
		destination.body_entered.connect(_destination_reached)
		break

func _destination_reached(_body: Node2D) -> void:
	destination_reached = true
	initial_destination_reached_position = global_position
	for destination in get_tree().get_nodes_in_group("destination"):
		distance_to_destination_center = global_position.distance_to(destination.global_position)
		direction_to_destination_center = global_position.direction_to(destination.global_position)
		break

func _setup_player() -> void:
	position = initial_position
	global_rotation = 0
	in_motion = false
	_handle_mouse_position_player_changes(get_viewport().get_mouse_position())
	$PlayerTexture.visible = true
	$ArrowSprite.visible = true

func _handle_mouse_position_player_changes(mouse_position: Vector2) -> void:
	var power_ratio: float = _calculate_power_ratio(global_position, mouse_position)
	var scale_ratio: float = _calculate_arrow_scale_ratio(power_ratio)
	var scale_y: float = scale_ratio * arrow_scale_factor
	$ArrowSprite.scale = Vector2($ArrowSprite.scale.x, scale_y)
	var scale_y_offset: float = _calculate_arrow_scale_y_offset(scale_y)
	$ArrowSprite.position = Vector2($ArrowSprite.position.x, arrow_y_offset + scale_y_offset)
	var angle_to_cursor: float = global_position.angle_to_point(mouse_position)
	global_rotation = angle_to_cursor + (PI / 2)
	initial_velocity_factor = _calculate_initial_velocity_factor(power_ratio)

# NOTE: We have to scale the mouse position based on the window stretch factor
# when the mouse position is given by the event object.
func _scale_mouse_position(mouse_position: Vector2) -> Vector2:
	var screen_transform: Transform2D = get_viewport().get_screen_transform()
	var window_offset: Vector2 = screen_transform.get_origin()
	mouse_position -= window_offset
	var window_scale: Vector2 = screen_transform.get_scale()
	mouse_position = Vector2(mouse_position.x / window_scale.x, mouse_position.y / window_scale.y)
	return mouse_position

func _make_explosion() -> void:
	exploding = true
	$PlayerTexture.visible = false
	$GPUParticles2D.restart()
	await get_tree().create_timer(1.0).timeout
	exploding = false
	_setup_player()
	# NOTE: the following is required to reset the slide collision count
	velocity = Vector2()
	move_and_slide()

func _ready():
	if Engine.is_editor_hint():
		return
	_setup_collision_shape()
	_setup_bounds_check()
	_setup_destination_collision_check()
	initial_position = position
	_setup_player()
	add_to_group("player")

func _input(event):
	if Engine.is_editor_hint():
		return
	if in_motion or exploding or destination_reached:
		return
	if event is InputEventMouseButton:
		var scaled_mouse_position: Vector2 = _scale_mouse_position(event.global_position)
		var direction: Vector2 = global_position.direction_to(scaled_mouse_position)
		velocity = direction * initial_velocity_factor
		$ArrowSprite.visible = false
		in_motion = true
	if event is InputEventMouseMotion:
		var scaled_mouse_position: Vector2 = _scale_mouse_position(event.global_position)
		_handle_mouse_position_player_changes(scaled_mouse_position)

func _physics_process(delta):
	if Engine.is_editor_hint():
		return
	if not in_motion or exploding or completed_level:
		return
	if destination_reached:
		if initial_destination_reached_position.distance_to(global_position) > distance_to_destination_center:
			completed_level = true
			emit_signal("player_completed_level")
			return
		global_position += direction_to_destination_center * distance_to_destination_center * delta
		return
	if get_slide_collision_count() > 0:
		_make_explosion()
		return
	for attractor in get_tree().get_nodes_in_group("attractors"):
		var direction: Vector2 = global_position.direction_to(attractor.global_position)
		var distance_squared: float = global_position.distance_squared_to(attractor.global_position)
		velocity += direction * ((attractor.radius ** 2) / distance_squared) * gravity_factor * delta
	move_and_slide()
