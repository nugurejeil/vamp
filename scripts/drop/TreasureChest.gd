extends Area2D
class_name TreasureChest

var is_opened: bool = false

@onready var sprite: Sprite2D = $Sprite2D

func _ready() -> void:
	add_to_group("TreasureChest")
	area_entered.connect(_on_area_entered)
	
	# 황금 상자 펄스 애니메이션
	var tween = create_tween().set_loops()
	tween.tween_property(sprite, "scale", Vector2(0.64, 0.64), 0.5)
	tween.tween_property(sprite, "scale", Vector2(0.56, 0.56), 0.5)

func _on_area_entered(area: Area2D) -> void:
	if is_opened:
		return
	if area.owner and area.owner.is_in_group("Player"):
		_open_chest()
	elif area.get_parent() and area.get_parent().is_in_group("Player"):
		_open_chest()

func _open_chest() -> void:
	is_opened = true
	set_deferred("monitoring", false)
	EventBus.chest_opened.emit()
	
	# 상자 오픈 이펙트 후 제거
	var tween = create_tween()
	tween.tween_property(sprite, "scale", Vector2(0.9, 0.9), 0.15)
	tween.parallel().tween_property(sprite, "modulate:a", 0.0, 0.15)
	tween.tween_callback(queue_free)
