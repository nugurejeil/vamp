extends Node2D
class_name DamageNumber

@onready var label: Label = $Label

static var scene_preload: PackedScene = preload("res://scenes/ui/DamageNumber.tscn")

static func spawn(tree: SceneTree, world_pos: Vector2, amount: float) -> void:
	if scene_preload == null or tree.current_scene == null:
		return
	var inst = scene_preload.instantiate() as DamageNumber
	inst.global_position = world_pos + Vector2(randf_range(-14, 14), randf_range(-14, 14))
	tree.current_scene.add_child.call_deferred(inst)
	inst.setup(amount)

func setup(amount: float) -> void:
	if not is_inside_tree():
		await ready
		
	var rounded = int(amount)
	label.text = str(rounded)
	
	# 대미지 규모에 따른 색상 및 크기 분기
	if rounded >= 35:
		label.modulate = Color(1.0, 0.3, 0.2, 1.0) # 강타: 진한 주황/적색
		scale = Vector2(1.8, 1.8)
	else:
		label.modulate = Color(1.0, 0.95, 0.8, 1.0) # 일반: 연한 크림색
		scale = Vector2(1.2, 1.2)
		
	# 위로 솟구치며 페이드아웃하는 애니메이션
	var tween = create_tween()
	var target_y = position.y - randf_range(45.0, 70.0)
	tween.tween_property(self, "position:y", target_y, 0.45).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(self, "scale", scale * 0.75, 0.45)
	tween.parallel().tween_property(label, "modulate:a", 0.0, 0.45)
	tween.tween_callback(queue_free)
