@tool
extends StaticBody2D

@export var radius: float = 20.0:
	get:
		return radius
	set(new_radius):
		radius = new_radius
		_set_sprite_radius()

func _set_sprite_radius() -> void:
	$CircleSprite.radius = radius

func _setup_collision_shape() -> void:
	var circle_shape: CircleShape2D = CircleShape2D.new()
	circle_shape.radius = radius
	var shape_owner_id: int = create_shape_owner(self)
	shape_owner_add_shape(shape_owner_id, circle_shape)

func _ready():
	_set_sprite_radius()
	if Engine.is_editor_hint():
		return
	_setup_collision_shape()
	add_to_group("attractors")
