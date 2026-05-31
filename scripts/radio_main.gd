extends Node

@onready var _music: AudioStreamPlayer2D = $"../MusicPlayer"
var is_playing: bool = true


func _ready() -> void:
	_music.play()
	# 连接到父节点（Radio Area2D 使用 interactable.gd）的 interacted 信号
	if get_parent().has_signal("interacted"):
		get_parent().interacted.connect(_on_radio_interacted)


func _on_radio_interacted() -> void:
	var lines: Array[String]
	if is_playing:
		_music.stop()
		is_playing = false
		lines = ["这台收音机正大声放着广场舞音乐……\n【按F键关闭】"]
	else:
		lines = ["收音机安静了。"]

	# 搜索场景中的 Player 节点传递给 DialogueManager
	var player := get_tree().current_scene.get_node_or_null("Player") as CharacterBody2D
	if player:
		DialogueManager.show_dialogue(
			lines,
			player,
			"res://scene/textboxB.tscn",
			func(): get_parent().unlock_interaction()
		)
