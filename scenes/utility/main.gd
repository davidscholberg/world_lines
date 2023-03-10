extends Node2D

var current_level: Node2D = null
var level_path_list: Array = [
	"res://scenes/environments/level_1.tscn",
	"res://scenes/environments/level_2.tscn",
	"res://scenes/environments/level_3.tscn",
	"res://scenes/environments/level_4.tscn",
	"res://scenes/environments/level_5.tscn",
]
var level_path_index: int = -1
var level_transition: bool = true
var game_ended: bool = false

func _transition_to_next_level() -> void:
	if current_level != null:
		remove_child(current_level)
		current_level.queue_free()
	level_path_index += 1
	if level_path_index > level_path_list.size() - 1:
		game_ended = true
	else:
		var level_scene: Resource = load(level_path_list[level_path_index])
		current_level = level_scene.instantiate()
		add_child(current_level)
		for player in get_tree().get_nodes_in_group("player"):
			player.player_completed_level.connect(_level_completed)
			break
	level_transition = false

func _level_completed() -> void:
	level_transition = true

func _process(_delta):
	if game_ended:
		$EndControl.visible = true
		return
	if level_transition:
		_transition_to_next_level()
