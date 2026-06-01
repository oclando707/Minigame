extends Area2D
## 毁灭装置关闭按钮
## A1 靠近按 F → 关闭全体机器人 + 收回所有尖刺 + 切换纹理


var player_in_range: bool = false
var pressed: bool = false


func _ready() -> void:
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)


func _process(_delta: float) -> void:
	if player_in_range and not pressed:
		if Input.is_action_just_pressed("interact"):
			_press()


func _press() -> void:
	pressed = true

	# 全局标记：所有机器人休眠
	DialogueManager.flags["robots_deactivated"] = true

	# 休眠当前场景中所有机器人
	for robot in get_tree().get_nodes_in_group("robots"):
		if robot.has_method("set_dormant"):
			robot.set_dormant()

	# 收回所有尖刺 —— 未来被改写了！
	for spike in get_tree().get_nodes_in_group("spikes"):
		if spike.has_method("retract"):
			spike.retract()

	# 切换纹理：关闭 → 开启
	var sprite: Sprite2D = $Sprite2D as Sprite2D
	if sprite:
		sprite.texture = load("res://minigame_assets/Level3-1/3-1A1/毁灭装置 开启.png")

	# 隐藏 F 提示
	var hint := $FHint if has_node("FHint") else null
	if hint:
		hint.visible = false


func _on_body_entered(body: Node2D) -> void:
	if body is CharacterBody2D and not pressed:
		player_in_range = true
		var hint := $FHint if has_node("FHint") else null
		if hint:
			hint.visible = true


func _on_body_exited(body: Node2D) -> void:
	if body is CharacterBody2D:
		player_in_range = false
		var hint := $FHint if has_node("FHint") else null
		if hint:
			hint.visible = false
