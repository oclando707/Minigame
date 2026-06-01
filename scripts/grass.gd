extends Area2D
## 变异草 — 玩家进入后隐身，机器人无法检测
## 玩家在草内按 Tab 键可切换到下一关


var _player_in_grass: bool = false


func _ready() -> void:
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)

	# 场景中已有的 TextureRect 提示贴图，初始不可见
	if has_node("TextureRect"):
		get_node("TextureRect").visible = false


func _input(event: InputEvent) -> void:
	if not _player_in_grass:
		return
	if event is InputEventKey and event.pressed and event.keycode == KEY_TAB:
		get_tree().change_scene_to_file("res://scene/level_1.tscn")


func _on_body_entered(body: Node2D) -> void:
	if body is CharacterBody2D:
		body.add_to_group("hidden")
		_player_in_grass = true
		_toggle_hint(true)


func _on_body_exited(body: Node2D) -> void:
	if body is CharacterBody2D:
		body.remove_from_group("hidden")
		_player_in_grass = false
		_toggle_hint(false)


func _toggle_hint(p_show: bool) -> void:
	if has_node("TextureRect"):
		get_node("TextureRect").visible = p_show
