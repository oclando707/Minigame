extends StaticBody2D

signal interacted

var player_in_range: bool = false
var interaction_locked: bool = false
var unlocked: bool = false

@onready var hint := $FHint if has_node("FHint") else null
@onready var tab_hint := $TabHint if has_node("TabHint") else null


func _ready():
	# 信号已通过 .tscn 连接，不在此重复连接
	pass


func _process(_delta):
	if player_in_range and not interaction_locked and not unlocked and Input.is_action_just_pressed("interact"):
		interaction_locked = true
		if hint:
			hint.visible = false
		interacted.emit()
		_on_unlock()

	# 门解锁后，按 Tab 切换场景
	if unlocked and player_in_range and Input.is_action_just_pressed("switch"):
		if tab_hint:
			tab_hint.visible = false
		get_tree().change_scene_to_file("res://scene/Level0-2_A2.tscn")


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

	# 显示 Tab 切换提示
	if tab_hint:
		tab_hint.visible = true


func _on_body_entered(body):
	if body is CharacterBody2D:
		player_in_range = true
		if not unlocked and hint:
			hint.visible = true
		if unlocked and tab_hint:
			tab_hint.visible = true


func _on_body_exited(body):
	if body is CharacterBody2D:
		player_in_range = false
		if hint:
			hint.visible = false
		if tab_hint:
			tab_hint.visible = false
