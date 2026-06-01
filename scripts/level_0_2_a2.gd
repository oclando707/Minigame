extends Node2D
## Level0-2_A2 场景：加载时播放草叶沙沙环境音

const BGM := "res://.godot/imported/Homecoming.wav-51edfeba606893f8fdc38e8c3eee105f.sample"


func _ready() -> void:
	get_node("/root/MusicManager").crossfade(BGM)

	var sfx := AudioStreamPlayer2D.new()
	sfx.stream = load("res://.godot/imported/dragon-studio-dry-grass-rustling-478361.mp3-e9fb42841347c6ed2ca6e431fa749875.mp3str")
	add_child(sfx)
	sfx.finished.connect(sfx.queue_free)
	sfx.play()
