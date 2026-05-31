extends StaticBody2D

signal interacted

var player_in_range: bool = false
var interaction_locked: bool = false
var unlocked: bool = false

@onready var hint := $FHint


func _ready():
	$InteractZone.body_entered.connect(_on_body_entered)
	$InteractZone.body_exited.connect(_on_body_exited)


func _process(_delta):
	if player_in_range and not interaction_locked and Input.is_action_just_pressed("interact"):
		interaction_locked = true
		hint.visible = false
		interacted.emit()
		_on_unlock()


func _on_unlock():
	if unlocked:
		return
	unlocked = true

	# 播放验证声
	if $AudioStreamPlayer2D.stream:
		$AudioStreamPlayer2D.play()

	# 弹对话
	var root = get_tree().current_scene
	if root.has_method("start_dialog"):
		root.start_dialog([
			"滴——验证通过！",
			"门开了。"
		])

	# 取消碰撞体，让玩家通过
	$CollisionShape2D.set_deferred("disabled", true)


func _on_body_entered(body):
	if body is CharacterBody2D and not unlocked:
		player_in_range = true
		hint.visible = true


func _on_body_exited(body):
	if body is CharacterBody2D:
		player_in_range = false
		hint.visible = false
