extends Node

## 当前是否正在显示对话
var is_active: bool = false

## 游戏进度标记：跨场景共享状态，用于控制节点显隐等进度相关逻辑
## 例如 modou_interacted → 与魔豆对话后解锁 lv_1_background_a_2 的 tree 和 picture
var flags: Dictionary = {}

var _canvas: CanvasLayer = null
var _dialog: Control = null
var _current_lines: Array[String] = []
var _current_index: int = 0
var _player: CharacterBody2D = null
var _on_finished: Callable = Callable()


## 显示对话
## lines: 对话文本数组
## player: 要冻结的玩家节点
## textbox_scene: 对话框场景路径（textboxA 或 textboxB）
## on_finished: 对话结束后的回调
func show_dialogue(
	lines: Array[String],
	player: CharacterBody2D,
	textbox_scene: String = "res://scene/textboxB.tscn",
	on_finished: Callable = Callable()
) -> void:
	if is_active:
		return
	if lines.is_empty():
		return

	is_active = true
	_player = player
	_on_finished = on_finished
	_current_lines = lines
	_current_index = 0

	player.set_movement_enabled(false)

	_canvas = CanvasLayer.new()
	player.get_parent().add_child(_canvas)

	var scene := load(textbox_scene) as PackedScene
	_dialog = scene.instantiate() as Control
	_canvas.add_child(_dialog)

	# 隐藏选项按钮和背景（与原行为一致）
	if _dialog.has_node("VBoxContainer"):
		_dialog.get_node("VBoxContainer").visible = false
	if _dialog.has_node("background"):
		_dialog.get_node("background").visible = false

	_show_current_line()


func _show_current_line() -> void:
	if _current_index < _current_lines.size():
		_dialog.get_node("text").set("text", _current_lines[_current_index])
	else:
		_close_dialogue()


func _input(event: InputEvent) -> void:
	if not is_active:
		return
	if event is InputEventKey and event.pressed:
		_current_index += 1
		_show_current_line()
		get_viewport().set_input_as_handled()


func _close_dialogue() -> void:
	if _canvas:
		_canvas.queue_free()
		_canvas = null
	_dialog = null
	_current_lines.clear()

	if _player:
		_player.set_movement_enabled(true)
		_player = null

	is_active = false

	if _on_finished.is_valid():
		_on_finished.call()
	_on_finished = Callable()
