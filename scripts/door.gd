extends StaticBody2D
## 门 — open() 后碰撞消失、贴图隐藏


func open() -> void:
	# 禁用碰撞
	if has_node("CollisionShape2D"):
		$CollisionShape2D.set_deferred("disabled", true)
	# 隐藏所有贴图
	for child in get_children():
		if child is Sprite2D:
			child.visible = false
