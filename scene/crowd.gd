extends Area2D
# 人群环境音：玩家走进播放，走出停止

var player_inside: bool = false

@onready var crowd_sfx: AudioStreamPlayer2D = $AudioStreamPlayer2D
@onready var detect_zone: Area2D = $InteractZone


func _ready() -> void:
	# 连接子Area2D的信号
	detect_zone.body_entered.connect(_on_crowd_entered)
	detect_zone.body_exited.connect(_on_crowd_exited)


func _on_crowd_entered(body: Node2D) -> void:
	if body is CharacterBody2D and not player_inside:
			player_inside = true
			crowd_sfx.play()


func _on_crowd_exited(body: Node2D) -> void:
	if body is CharacterBody2D:
			player_inside = false
			crowd_sfx.stop()
