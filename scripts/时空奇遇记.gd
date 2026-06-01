extends Control

const SET_MENU_PATH := "res://scene/set_menu.tscn"

const SAVE_MENU_PATH := "res://scene/save.tscn"

var _set_menu: Control = null
var _save_menu: Control = null


func _ready() -> void:
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

	_set_menu.get_node("ExitBtn").pressed.connect(_close_settings)
	get_node("/root/MusicManager").bind_hover_sfx(_set_menu.get_node("ExitBtn"))
	


func _on_save_button_pressed() -> void:
	if _save_menu:
		return

	var scene := load(SAVE_MENU_PATH) as PackedScene
	_save_menu = scene.instantiate() as Control
	add_child(_save_menu)

	var close_btn := _save_menu.get_node("CloseBtn") as TextureButton
	close_btn.pressed.connect(_close_save)
	get_node("/root/MusicManager").bind_hover_sfx(close_btn)


func _close_settings() -> void:
	if _set_menu:
		_set_menu.queue_free()
		_set_menu = null


func _close_save() -> void:
	if _save_menu:
		_save_menu.queue_free()
		_save_menu = null
