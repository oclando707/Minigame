extends StaticBody2D
## 门 — open() 后碰撞消失、贴图隐藏


func open() -> void:
	if has_node("CollisionShape2D"):
		$CollisionShape2D.set_deferred("disabled", true)
	if has_node("Sprite2D"):
		$Sprite2D.visible = false
