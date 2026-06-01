extends Node2D

const BGM_LEVEL_0_1 := "res://.godot/imported/第二关.mp3-35875a80c07bf0b6977212394ec51378.mp3str"

var _canvas: CanvasLayer = null
var _dialog: Control = null
var _current_lines: Array = []
var _current_line: int = 0
var _dialog_source: Node = null


## 场景就绪时设置摄像机右边界为 3048（level_0_1 场景更宽）
func _ready() -> void:
	$Player/Camera2D.limit_right = 3048
	get_node("/root/MusicManager").play(BGM_LEVEL_0_1)


func start_dialog(lines: Array, source: Node = null) -> void:
	if _dialog:
		return
	if lines.is_empty():
		return

	$Player.set_movement_enabled(false)

	_canvas = CanvasLayer.new()
	add_child(_canvas)

	var scene := preload("res://scene/textboxB.tscn") as PackedScene
	_dialog = scene.instantiate() as Control
	_canvas.add_child(_dialog)

	if _dialog.has_node("VBoxContainer"):
		_dialog.get_node("VBoxContainer").visible = false

	_current_lines = lines
	_current_line = 0
	_dialog_source = source
	_show_current_line()


func _show_current_line() -> void:
	if _current_line < _current_lines.size():
		var label := _dialog.get_node("text") as Label
		label.text = _current_lines[_current_line]
	else:
		_close_dialog()


func _input(event: InputEvent) -> void:
	if not _dialog:
		return
	if event is InputEventKey and event.pressed:
		_current_line += 1
		_show_current_line()
		get_viewport().set_input_as_handled()


func _close_dialog() -> void:
	_canvas.queue_free()
	_canvas = null
	_dialog = null

	$Player.set_movement_enabled(true)

	if _dialog_source and _dialog_source.has_method("unlock_interaction"):
		_dialog_source.unlock_interaction()
	_dialog_source = null


func _on_radio_interacted() -> void:
	start_dialog([
		"这台播音机正大声放着广场舞音乐……",
	], $Radio)
