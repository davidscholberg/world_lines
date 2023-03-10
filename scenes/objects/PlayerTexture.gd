@tool
extends Node2D

func _draw():
	draw_circle(Vector2(), get_parent().radius, Color.SLATE_GRAY)
