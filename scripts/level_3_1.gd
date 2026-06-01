extends Node2D
## 关卡3-1：时空分割线
## Tab 切换操控 A1(过去) <-> A2(未来)，摄像机跟随两人中点
## A1 关闭毁灭装置 -> 全体机器人休眠 -> A2 安全通过
## 魔豆种下 -> A2侧藤蔓生长


var active_key: String = "A1"
var _has_modou: bool = false
var _near_earth: bool = false

@onready var a1: CharacterBody2D = $A1
@onready var a2: CharacterBody2D = $A2
@onready var anchor: Node2D = $CameraAnchor


func _ready() -> void:
	a1.get_node("Camera2D").enabled = false
	a2.get_node("Camera2D").enabled = false
	$CameraAnchor/Camera2D.enabled = true
	$CameraAnchor/Camera2D.make_current()
	a1.get_node("cha").flip_h = true
	a1.set_movement_enabled(true)
	a2.set_movement_enabled(false)
	_update_camera()

	if has_node("Modou"):
		$Modou.interacted.connect(_on_modou_picked)

	if has_node("PassID"):
		$PassID.interacted.connect(_on_passid_interacted)

	if has_node("Earth"):
		$Earth.body_entered.connect(func(b: Node2D):
			if b is CharacterBody2D: _near_earth = true)
		$Earth.body_exited.connect(func(b: Node2D):
			if b is CharacterBody2D: _near_earth = false)

	# A1 穿过灯光区域 → A2 尖刺永久缩回
	if has_node("LightExitZone"):
		$LightExitZone.body_entered.connect(func(b: Node2D):
			if b is CharacterBody2D:
				var spine := $Spine as Area2D
				if spine and spine.has_method("retract"):
					spine.retract()
		)

	_update_vine()


func _process(_delta: float) -> void:
	if Input.is_action_just_pressed("switch"):
		_swap_player()
	if _near_earth and _has_modou and Input.is_action_just_pressed("interact"):
		_on_earth_used()
	_update_camera()


func _swap_player() -> void:
	if active_key == "A1":
		a1.set_movement_enabled(false)
		a2.set_movement_enabled(true)
		active_key = "A2"
	else:
		a2.set_movement_enabled(false)
		a1.set_movement_enabled(true)
		active_key = "A1"


func _update_camera() -> void:
	var mx: float = (a1.global_position.x + a2.global_position.x) / 2.0
	anchor.global_position.x = mx


func _on_modou_picked() -> void:
	if _has_modou:
		return
	_has_modou = true
	var lines: Array[String] = ["一颗发光的豆子...", "也许种下去会长出什么。"]
	DialogueManager.show_dialogue(lines, a1, "res://scene/textboxB.tscn", func():
		if has_node("Modou"):
			$Modou.visible = false
	)


func _on_earth_used() -> void:
	var lines: Array[String] = ["把魔豆埋进土里。", "也许未来会长出什么..."]
	DialogueManager.show_dialogue(lines, a1, "res://scene/textboxB.tscn", func():
		DialogueManager.flags["modou_planted"] = true
		_has_modou = false
		_update_vine()
	)


func _update_vine() -> void:
	var planted: bool = DialogueManager.flags.get("modou_planted", false)
	if has_node("Vine_A2"):
		$Vine_A2.visible = planted


func _on_passid_interacted() -> void:
	a1.set_movement_enabled(false)

	var popup := preload("res://scene/passid_popup.tscn").instantiate() as Control
	get_tree().current_scene.add_child(popup)

	# 关闭 → 什么也不做
	popup.get_node("btn_close").pressed.connect(func():
		a1.set_movement_enabled(true)
		popup.queue_free()
		if has_node("PassID"):
			$PassID.unlock_interaction()
	)

	# 确认 → 关机密文件 → 弹出死难者名单
	popup.get_node("btn_ok").pressed.connect(func():
		DialogueManager.flags["passid_read"] = true
		popup.queue_free()

		var popup2 := preload("res://scene/victim_list_popup.tscn").instantiate() as Control
		get_tree().current_scene.add_child(popup2)

		popup2.get_node("btn_close").pressed.connect(func():
			a1.set_movement_enabled(true)
			popup2.queue_free()
			if has_node("PassID"):
				$PassID.unlock_interaction()
		)
	)
