extends Control
## 暂停菜单脚本 — 挂载于 pause_menu.tscn 根 Control 节点。
## 通过 PROCESS_MODE_ALWAYS 确保场景树暂停时仍能响应输入。
## 设置菜单（set_menu.tscn）在此内部处理。

const SET_MENU_PATH := "res://scene/set_menu.tscn"

signal continue_game
signal quit_game

var _set_menu: Control = null


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS

	for btn: TextureButton in [$Button/continue, $Button/set, $Button/TextureButton]:
		get_node("/root/MusicManager").bind_hover_sfx(btn)

	$Button/continue.pressed.connect(func(): continue_game.emit())
	$Button/set.pressed.connect(_on_settings_pressed)
	$Button/TextureButton.pressed.connect(func(): quit_game.emit())


func _on_settings_pressed() -> void:
	if _set_menu:
		return

	var scene := load(SET_MENU_PATH) as PackedScene
	_set_menu = scene.instantiate() as Control
	add_child(_set_menu)

	for btn_name: String in ["ExitBtn", "CancelBtn", "ApplyBtn"]:
		var btn := _set_menu.get_node(btn_name) as TextureButton
		btn.pressed.connect(_close_settings)
		get_node("/root/MusicManager").bind_hover_sfx(btn)


func _close_settings() -> void:
	if _set_menu:
		_set_menu.queue_free()
		_set_menu = null
