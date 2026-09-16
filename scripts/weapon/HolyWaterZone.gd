extends Area2D
class_name HolyWaterZone

@export var damage: float = 18.0
@export var lifetime: float = 3.0
@export var tick_interval: float = 0.35

var might_multiplier: float = 1.0
var is_evolved: bool = false
var player: Node2D = null

@onready var sprite: Sprite2D = $Sprite2D
@onready var shape: CollisionShape2D = $CollisionShape2D

func _ready() -> void:
	player = get_tree().get_first_node_in_group("Player")
	
	# 수명 타이머
	var life_timer = get_tree().create_timer(lifetime)
	life_timer.timeout.connect(_on_lifetime_end)
	
	# 틱 타이머
	var tick_timer = Timer.new()
	tick_timer.wait_time = tick_interval
	tick_timer.timeout.connect(_deal_tick_damage)
	add_child(tick_timer)
	tick_timer.start()
	
	# 초기 확산 애니메이션
	scale = Vector2.ZERO
	var tween = create_tween()
	tween.tween_property(self, "scale", Vector2.ONE, 0.25)

func _physics_process(delta: float) -> void:
	if is_evolved and is_instance_valid(player):
		# 라 보라: 화염 장판이 플레이어를 따라 서서히 이동
		var dir = global_position.direction_to(player.global_position)
		global_position += dir * 60.0 * delta

func _deal_tick_damage() -> void:
	for area in get_overlapping_areas():
		if area.is_in_group("EnemyHurtbox"):
			var enemy = area.owner if area.owner else area.get_parent()
			if enemy and enemy.has_method("take_damage") and not enemy.get("is_dead"):
				enemy.take_damage(damage * might_multiplier)

func _on_lifetime_end() -> void:
	var tween = create_tween()
	tween.tween_property(self, "scale", Vector2.ZERO, 0.2)
	tween.tween_callback(queue_free)
