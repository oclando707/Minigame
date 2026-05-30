extends Control

func _on_quit_button_pressed() -> void:
	get_tree().quit()

func _on_setting_button_pressed() -> void:
	get_tree().change_scene_to_file("res://Settings.tscn")

func _on_save_button_pressed() -> void:
	get_tree().change_scene_to_file("res://Save Interface.tscn")

func _on_start_button_pressed() -> void:
	get_tree().change_scene_to_file("res://Level1.tscn")
