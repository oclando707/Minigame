extends Area2D

signal interacted

var player_in_range: bool = false
var interaction_locked: bool = false
var is_playing := true

@onready var music := $MusicPlayer
@onready var f_hint := $FHint


func _ready() -> void:
	music.play()
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)


func _process(_delta: float) -> void:
	if player_in_range and not interaction_locked and Input.is_action_just_pressed("interact"):
		interaction_locked = true
		f_hint.visible = false
		interacted.emit()
		show_dialogue()


func show_dialogue() -> void:
	var textbox = preload("res://scene/textboxB.tscn").instantiate()

	if is_playing:
		textbox.get_node("text").text = "这台收音机正大声放着广场舞音乐……\n【按F键关闭】"
		music.stop()
		is_playing = false
	else:
		textbox.get_node("text").text = "收音机安静了。"

	get_tree().current_scene.add_child(textbox)


func _on_body_entered(body: Node2D) -> void:
	if body is CharacterBody2D and not interaction_locked:
		player_in_range = true
		f_hint.visible = true


func _on_body_exited(body: Node2D) -> void:
	if body is CharacterBody2D:
		player_in_range = false
		f_hint.visible = false


func unlock_interaction() -> void:
	interaction_locked = false
	if player_in_range:
		f_hint.visible = true
