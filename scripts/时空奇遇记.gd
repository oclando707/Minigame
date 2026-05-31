extends Control

const SET_MENU_PATH := "res://scene/set_menu.tscn"

var _set_menu: Control = null


func _on_start_button_pressed() -> void:
	get_tree().change_scene_to_file("res://scene/level_1.tscn")


func _on_quit_button_pressed() -> void:
	get_tree().quit()


func _on_setting_button_pressed() -> void:
	if _set_menu:
		return

	var scene := load(SET_MENU_PATH) as PackedScene
	_set_menu = scene.instantiate() as Control
	add_child(_set_menu)

	_set_menu.get_node("ExitBtn").pressed.connect(_close_settings)
	


func _on_save_button_pressed() -> void:
	pass


func _close_settings() -> void:
	if _set_menu:
		_set_menu.queue_free()
		_set_menu = null
		
