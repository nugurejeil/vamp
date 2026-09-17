extends Node2D
class_name WeaponHolyWater

@export var zone_scene: PackedScene = preload("res://scenes/weapon/HolyWaterZone.tscn")
@export var attack_interval: float = 3.0
@export var bottle_count: int = 1
@export var damage: float = 20.0
@export var throw_range: float = 350.0

var might_multiplier: float = 1.0
var cooldown_multiplier: float = 1.0:
	set(val):
		cooldown_multiplier = val
		_update_cooldown()

var is_evolved: bool = false
@onready var cooldown_timer: Timer = $CooldownTimer

func _ready() -> void:
	_update_cooldown()
	cooldown_timer.timeout.connect(_on_cooldown_timeout)
	cooldown_timer.start()

func _update_cooldown() -> void:
	if cooldown_timer:
		cooldown_timer.wait_time = max(0.5, attack_interval * cooldown_multiplier)

func apply_level(lvl: int) -> void:
	damage = 20.0 + (lvl - 1) * 6.0
	if lvl >= 3: bottle_count = 2
	if lvl >= 6: bottle_count = 3
	attack_interval = max(1.5, 3.0 - (lvl - 1) * 0.2)
	_update_cooldown()

func evolve() -> void:
	is_evolved = true
	damage = 42.0
	bottle_count = 4
	attack_interval = 1.8
	_update_cooldown()

func _on_cooldown_timeout() -> void:
	for i in range(bottle_count):
		_throw_bottle()

func _throw_bottle() -> void:
	if zone_scene == null:
		return
		
	AudioManager.play_shoot()
		
	# 주변 적 위치 우선, 없으면 랜덤 위치에 투척
	var target_pos = global_position
	var enemies = get_tree().get_nodes_in_group("Enemy")
	if enemies.size() > 0:
		var valid_enemies = enemies.filter(func(e): return is_instance_valid(e) and not e.get("is_dead"))
		if valid_enemies.size() > 0:
			var rand_enemy = valid_enemies.pick_random()
			target_pos = rand_enemy.global_position
		else:
			target_pos += Vector2(randf_range(-throw_range, throw_range), randf_range(-throw_range, throw_range))
	else:
		target_pos += Vector2(randf_range(-throw_range, throw_range), randf_range(-throw_range, throw_range))
		
	var zone = zone_scene.instantiate() as HolyWaterZone
	zone.global_position = target_pos
	zone.damage = damage
	zone.might_multiplier = might_multiplier
	zone.is_evolved = is_evolved
	
	if is_evolved:
		zone.scale = Vector2(1.5, 1.5)
		if zone.has_node("Sprite2D"):
			zone.get_node("Sprite2D").modulate = Color(0.1, 0.4, 1.0, 0.55) # 짙은 성스러운 푸른 불꽃
			
	get_tree().current_scene.add_child.call_deferred(zone)
