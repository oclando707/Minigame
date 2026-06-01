extends Node
## 全局星星管理器（Autoload 单例）
## 跨场景持久追踪金银星星数量，判定最终结局

# 银色/灰色星星数量（现实值）
var silver: int = 0

# 金色/黄色星星数量（希望值）
var gold: int = 0


## 返回结局类型："hope"（希望结局）或 "reality"（现实结局）
func get_ending() -> String:
	if silver <= gold:
		return "hope"
	else:
		return "reality"


## 返回格式化的星星统计字符串（调试/UI用）
func get_stats() -> String:
	return "银色:%d  金色:%d" % [silver, gold]


## 重置所有星星计数（新游戏/全部重开时调用）
func reset_all() -> void:
	silver = 0
	gold = 0
