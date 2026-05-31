extends Node

@onready var _music: AudioStreamPlayer2D = $"../MusicPlayer"
var is_playing: bool = true


func _ready() -> void:
	_music.play()


## 由关卡脚本在接收到 interacted 信号后调用
func toggle_music() -> void:
	if is_playing:
		_music.stop()
		is_playing = false
	else:
		_music.play()
		is_playing = true
