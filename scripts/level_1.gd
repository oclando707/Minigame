extends Node2D

@export var dialog_lines: Array[String] = [
	"“帕克！还记得我们的时间胶囊埋在哪里吗！”",
	"犬吠，像是在回应",
	"“好帕克好帕克！我就知道你也记得！”",
	"“不过我本来是打算和魔豆埋在一起的来着……”",
	"小男孩的声音渐渐小下去，像是自言自语。",
	"“哇啊！”",
	"他扭头看见了你，被吓了一跳，带着小狗跑开了"
	]

var _canvas: CanvasLayer = null
var _dialog: Control = null
var _current_line: int = 0



func _on_jack_interacted() -> void:
	if _dialog:
		return

	# 冻结玩家
	var player: CharacterBody2D = $Player
	player.set_movement_enabled(false)

	# CanvasLayer 让 Control 在 Node2D 下也能正确渲染
	_canvas = CanvasLayer.new()
	add_child(_canvas)

	var scene := preload("res://scene/textboxA.tscn") as PackedScene
	_dialog = scene.instantiate() as Control
	_canvas.add_child(_dialog)

	# 隐藏选项按钮和全屏黑色背景，只显示对话框底图和文字
	if _dialog.has_node("VBoxContainer"):
		_dialog.get_node("VBoxContainer").visible = false
	#if _dialog.has_node("background"):
	#	_dialog.get_node("background").visible = false

	_current_line = 0
	_show_current_line()


func _show_current_line() -> void:
	if _current_line < dialog_lines.size():
		_dialog.get_node("text").set("text", dialog_lines[_current_line])
	else:
		_close_dialog()
		$jack.visible = false
		

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

	var player: CharacterBody2D = $Player
	player.set_movement_enabled(true)
