@tool
extends Sprite2D

const image_radius: int = 512

var radius: float = 50.0:
	get:
		return radius
	set(new_radius):
		radius = new_radius
		_set_scale()

func _set_scale() -> void:
	scale = Vector2(1, 1)
	scale *= radius / image_radius

func _ready():
	_set_scale()
