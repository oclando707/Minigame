extends Node2D

@export var yiwu_lines: Array[String] = [
	"你好，我是yiwu的对话内容。"
]

@export var picture_lines: Array[String] = [
	"一张儿童画的残骸。",
	"不知为何你觉得这张画十分眼熟，心中升起些隔着雾一般的悲哀。",
	"真是奇怪。",
	"“……我见过这张画的全貌？……想不起来”"
]

var _canvas: CanvasLayer = null
var _dialog: Control = null
var _current_lines: Array[String] = []
var _current_line: int = 0
var _dialog_source: Node = null


# ── 遗物的对话 ────────────────────────────

func _on_yiwu_interacted() -> void:
	if _dialog:
		return
	_dialog_source = $prop/yiwu
	_start_dialog(yiwu_lines)


# ── 简笔画的对话 ────────────────────────────

func _on_picture_interacted() -> void:
	if _dialog:
		return
	_dialog_source = $prop/picture
	_start_dialog(picture_lines)


# ── 通用对话引擎 ────────────────────────────

func _start_dialog(lines: Array[String]) -> void:
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
	if _dialog.has_node("background"):
		_dialog.get_node("background").visible = false

	_current_lines = lines
	_current_line = 0
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

	# 对话结束后解锁 NPC，允许再次交互
	if _dialog_source and _dialog_source.has_method("unlock_interaction"):
		_dialog_source.unlock_interaction()
	_dialog_source = null
