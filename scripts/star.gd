extends Area2D
## 星星收集物 — 挂到关卡中的星星 Area2D 节点上
## Inspector 里选择 star_type：Silver（灰色）或 Gold（金色）

enum StarType { SILVER, GOLD }

@export var star_type: StarType = StarType.SILVER

@onready var sfx: AudioStreamPlayer2D = get_node_or_null("AudioStreamPlayer2D") as AudioStreamPlayer2D
@onready var sprite: Sprite2D = $Sprite2D


func _ready() -> void:
	body_entered.connect(_on_body_entered)


func _on_body_entered(body: Node2D) -> void:
	if not (body is CharacterBody2D):
		return

	# 防止重复收集
	set_deferred("monitoring", false)
	set_deferred("monitorable", false)

	# 播放音效
	if sfx and sfx.stream:
		sfx.play()

	# 隐藏图像
	if sprite:
		sprite.visible = false

	# 累加全局计数
	match star_type:
		StarType.SILVER:
			StarManager.silver += 1
		StarType.GOLD:
			StarManager.gold += 1

	# 等音效播完再移除
	if sfx and sfx.stream:
		await get_tree().create_timer(0.5).timeout
	queue_free()
