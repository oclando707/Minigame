extends Area2D
## 尖刺陷阱 / 危险区
## 玩家进入即死。A1按下毁灭装置后，所有尖刺收回地下


@export var retract_distance: float = 200.0    ## 尖刺收回的像素距离
@export var retract_duration: float = 0.8      ## 收回动画时长(秒)

var retracted: bool = false


func _ready() -> void:
	add_to_group("spikes")
	body_entered.connect(_on_body_entered)


func _on_body_entered(body: Node2D) -> void:
	if retracted:
		return  # 已收回，安全
	if body is CharacterBody2D:
		get_tree().reload_current_scene()


## A1按下毁灭装置后由 shutdown_button 调用
func retract() -> void:
	if retracted:
		return
	retracted = true

	# 禁用碰撞，玩家可安全通过
	if has_node("CollisionShape2D"):
		$CollisionShape2D.set_deferred("disabled", true)

	# Tween：尖刺沉入地下（未来被改写！）
	var tw := create_tween()
	tw.set_ease(Tween.EASE_IN_OUT)
	tw.set_trans(Tween.TRANS_QUAD)
	tw.tween_property(self, "position:y", position.y + retract_distance, retract_duration)
