extends Area2D

var player_in_range: bool = false
var used: bool = false


func _ready():
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)


func _process(_delta):
	$"../FHint".visible = player_in_range and not used

	if player_in_range and not used and Input.is_action_just_pressed("interact"):
		used = true
		$"../FHint".visible = false
		# 调用根节点的对话系统
		var root = get_tree().current_scene
		if root.has_method("start_dialog"):
			root.start_dialog([
				"大清早的，放置它的人应该是去买菜了",
				
			])


func _on_body_entered(body):
	if body is CharacterBody2D:
		player_in_range = true


func _on_body_exited(body):
	if body is CharacterBody2D:
		player_in_range = false
		used = false
		$"../FHint".visible = false
