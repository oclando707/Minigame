extends Control

const SET_MENU_PATH := "res://scene/set_menu.tscn"
const SAVE_MENU_PATH := "res://scene/save.tscn"

var _set_menu: Control = null
var _save_menu: Control = null


func _ready() -> void:
	get_node("/root/MusicManager").play(MusicManager.BGM_MAIN_MENU)
	for btn in [$BtnStart, $BtnQuit, $BtnSetting, $BtnSave]:
		get_node("/root/MusicManager").bind_hover_sfx(btn)


func _on_start_button_pressed() -> void:
	get_tree().change_scene_to_file("res://scene/level_0_1.tscn")


func _on_quit_button_pressed() -> void:
	get_tree().quit()


func _on_setting_button_pressed() -> void:
	if _set_menu:
		return

	var scene := load(SET_MENU_PATH) as PackedScene
	_set_menu = scene.instantiate() as Control
	add_child(_set_menu)

	_set_menu.closed.connect(_close_settings)

	UIAnim.pop_in(_set_menu)


## BtnSave 按钮 — 弹出存档/选关界面（1920×1080）
## save.tscn 作为子节点添加到此 Main Control（1920×1080）下。
## save.tscn 根节点 SavePanel 通过 anchors_preset=15 撑满父容器。
func _on_save_button_pressed() -> void:
	if _save_menu:
		return

	var scene := load(SAVE_MENU_PATH) as PackedScene
	_save_menu = scene.instantiate() as Control
	add_child(_save_menu)

	var close_btn := _save_menu.get_node("CloseBtn") as TextureButton
	close_btn.pressed.connect(_close_save)
	get_node("/root/MusicManager").bind_hover_sfx(close_btn)

	UIAnim.pop_in(_save_menu)


func _close_settings() -> void:
	if _set_menu:
		var menu := _set_menu
		_set_menu = null
		UIAnim.pop_out(menu, func(): menu.queue_free())


func _close_save() -> void:
	if _save_menu:
		var menu := _save_menu
		_save_menu = null
		UIAnim.pop_out(menu, func(): menu.queue_free())
