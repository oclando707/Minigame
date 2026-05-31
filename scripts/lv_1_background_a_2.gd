extends Node2D

@export var yiwu_lines: Array[String] = [
	"“帕克！还记得我们的时间胶囊埋在哪里吗！”",
	"犬吠，像是在回应",
	"“好帕克好帕克！我就知道你也记得！”",
	"“不过我本来是打算和魔豆埋在一起的来着……”",
	"小男孩的声音渐渐小下去，像是自言自语。",
	"“哇啊！”",
	"他扭头看见了你，被吓了一跳，带着小狗跑开了"
]

@export var picture_lines: Array[String] = [
	"一张儿童画的残骸。",
	"不知为何你觉得这张画十分眼熟……",
	"心中升起些隔着雾一般的悲哀，真是奇怪。",
	"“……我见过这张画的全貌？……想不起来”"
]

var _canvas: CanvasLayer = null
var _dialog: Control = null
var _current_lines: Array[String] = []
var _current_line: int = 0


# ── 遗物的对话 ────────────────────────────

func _on_yiwu_interacted() -> void:
	if _dialog:
		return
	_start_dialog(yiwu_lines)


# ── 简笔画的对话 ────────────────────────────

func _on_picture_interacted() -> void:
	if _dialog:
		return
	_start_dialog(picture_lines)


# ── 通用对话引擎 ────────────────────────────

func _start_dialog(lines: Array[String]) -> void:
	if lines.is_empty():
		return

	# 冻结玩家
	$Player.set_movement_enabled(false)

	# CanvasLayer 让 Control 在 Node2D 下也能正确渲染
	_canvas = CanvasLayer.new()
	add_child(_canvas)

	var scene := preload("res://scene/textboxB.tscn") as PackedScene
	_dialog = scene.instantiate() as Control
	_canvas.add_child(_dialog)

	# 只显示对话框底图和文字
	if _dialog.has_node("VBoxContainer"):
		_dialog.get_node("VBoxContainer").visible = false
	#if _dialog.has_node("background"):
	#	_dialog.get_node("background").visible = false

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
