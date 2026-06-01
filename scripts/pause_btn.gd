extends Control
## 暂停按钮脚本 — 挂载于 pause.tscn 根 Control 节点。
## 点击后暂停场景树，弹出暂停菜单。

const PAUSE_MENU_PATH := "res://scene/pause_menu.tscn"

var _pause_menu: Control = null


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS

	get_node("/root/MusicManager").bind_hover_sfx($TextureButton)

	$TextureButton.pressed.connect(_on_pause_pressed)


func _on_pause_pressed() -> void:
	if _pause_menu:
		return

	get_tree().paused = true

	var scene := load(PAUSE_MENU_PATH) as PackedScene
	_pause_menu = scene.instantiate() as Control

	var canvas_layer := get_parent()
	if not canvas_layer:
		push_error("pause_btn: 找不到父 CanvasLayer，无法打开暂停菜单")
		get_tree().paused = false
		return
	canvas_layer.add_child(_pause_menu)

	_pause_menu.continue_game.connect(_on_continue)
	_pause_menu.quit_game.connect(_on_quit)

	UIAnim.pop_in(_pause_menu)


func _on_continue() -> void:
	if _pause_menu:
		var menu := _pause_menu
		_pause_menu = null
		UIAnim.pop_out(menu, func():
			menu.queue_free()
			get_tree().paused = false
		)


func _on_quit() -> void:
	if _pause_menu:
		var menu := _pause_menu
		_pause_menu = null
		UIAnim.pop_out(menu, func():
			menu.queue_free()
			get_tree().paused = false
			get_tree().change_scene_to_file("res://scene/时空奇遇记.tscn")
		)
