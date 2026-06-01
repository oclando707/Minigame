extends Area2D
## 实验室入口 — A1 进入后打开 A1 侧的门


@export var door_to_open: NodePath   ## A1进入后要打开的门

var _triggered: bool = false


func _ready() -> void:
	body_entered.connect(_on_body_entered)


func _on_body_entered(body: Node2D) -> void:
	if _triggered:
		return
	if not (body is CharacterBody2D):
		return
	_triggered = true

	if door_to_open.is_empty():
		return
	var door := get_node(door_to_open) as StaticBody2D
	if door and door.has_method("open"):
		door.open()
