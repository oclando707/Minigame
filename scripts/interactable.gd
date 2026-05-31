extends Area2D
class_name Interactable

## 玩家进入范围并按下交互键时触发
signal interacted

## 是否显示提示图标（TextureRect 或 FHint Label）
@export var show_prompt: bool = true

var player_in_range: bool = false
var interaction_locked: bool = false


func _ready() -> void:
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)


func _unhandled_input(event: InputEvent) -> void:
	if not player_in_range:
		return
	if interaction_locked:
		return
	if event.is_action_pressed("interact") and not event.is_echo():
		get_viewport().set_input_as_handled()
		interaction_locked = true
		_set_prompt_visible(false)
		interacted.emit()


func _on_body_entered(body: Node2D) -> void:
	if body is CharacterBody2D:
		player_in_range = true
		if not interaction_locked:
			_set_prompt_visible(true)


func _on_body_exited(body: Node2D) -> void:
	if body is CharacterBody2D:
		player_in_range = false
		_set_prompt_visible(false)


## 解锁交互，允许再次触发（由对话系统调用）
func unlock_interaction() -> void:
	interaction_locked = false
	if player_in_range:
		_set_prompt_visible(true)


## 隐藏或显示提示图标
func _set_prompt_visible(v: bool) -> void:
	if not show_prompt:
		return
	var node := get_node_or_null("TextureRect") as TextureRect
	if node:
		node.visible = v
	var label := get_node_or_null("FHint") as Label
	if label:
		label.visible = v
