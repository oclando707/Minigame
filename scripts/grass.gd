extends Area2D
## 变异草 — 玩家进入后隐身，机器人无法检测


func _ready() -> void:
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)


func _on_body_entered(body: Node2D) -> void:
	if body is CharacterBody2D:
		body.add_to_group("hidden")


func _on_body_exited(body: Node2D) -> void:
	if body is CharacterBody2D:
		body.remove_from_group("hidden")
