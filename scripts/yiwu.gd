extends Area2D

signal interacted

var player_in_range: bool = false
var interaction_locked: bool = false


func _ready() -> void:
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)


func _process(_delta: float) -> void:
	if player_in_range and not interaction_locked and Input.is_action_just_pressed("interact"):
		interaction_locked = true
		$TextureRect.visible = true
		interacted.emit()


func _on_body_entered(body: Node2D) -> void:
	if body is CharacterBody2D and not interaction_locked:
		player_in_range = true
		$TextureRect.visible = true


func _on_body_exited(body: Node2D) -> void:
	if body is CharacterBody2D:
		player_in_range = false
		$TextureRect.visible = false


func unlock_interaction() -> void:
	interaction_locked = false
	if player_in_range:
		$TextureRect.visible = true
