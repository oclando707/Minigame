extends Area2D

@onready var music := $MusicPlayer
var is_playing := true
var can_interact := false

func _ready():
	music.play()

func _process(_delta):
	if can_interact and Input.is_action_just_pressed("interact"):
		show_dialogue()

func show_dialogue():
	var textbox = preload("res://scene/textboxB.tscn").instantiate()

	if is_playing:
		textbox.get_node("text").text = "这台收音机正大声放着广场舞音乐……\n【按F键关闭】"
		music.stop()
		is_playing = false
	else:
		textbox.get_node("text").text = "收音机安静了。"

	get_tree().current_scene.add_child(textbox)

func _on_interact_zone_body_entered(body):
	if body.name == "Player":
		can_interact = true

func _on_interact_zone_body_exited(body):
	if body.name == "Player":
		can_interact = false
