extends Node2D
class_name WeaponMagicMissile

@export var projectile_scene: PackedScene = preload("res://scenes/weapon/MagicMissileProjectile.tscn")
@export var attack_interval: float = 1.0
@export var attack_range: float = 850.0
@export var damage: float = 25.0

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
		cooldown_timer.wait_time = max(0.08, attack_interval * cooldown_multiplier)

func apply_level(lvl: int) -> void:
	damage = 25.0 + (lvl - 1) * 8.0
	attack_interval = max(0.25, 1.0 - (lvl - 1) * 0.08)
	_update_cooldown()

func evolve() -> void:
	is_evolved = true
	damage = 50.0
	attack_interval = 0.15 # 기관총 연사
	_update_cooldown()

func _on_cooldown_timeout() -> void:
	var target = _find_closest_enemy()
	if target != null:
		_shoot_at(target.global_position)
		if is_evolved:
			# 진화 무기(홀리 완드)는 추가 연사 투사체 발사
			get_tree().create_timer(0.06).timeout.connect(func():
				if is_instance_valid(target): _shoot_at(target.global_position)
			)

func _find_closest_enemy() -> Node2D:
	var enemies = get_tree().get_nodes_in_group("Enemy")
	var closest_enemy: Node2D = null
	var min_distance := attack_range
	
	for enemy in enemies:
		if not is_instance_valid(enemy) or not enemy.is_inside_tree() or enemy.get("is_dead"):
			continue
		var dist = global_position.distance_to(enemy.global_position)
		if dist < min_distance:
			min_distance = dist
			closest_enemy = enemy
			
	return closest_enemy

func _shoot_at(target_pos: Vector2) -> void:
	if projectile_scene == null:
		return
		
	AudioManager.play_shoot()
	var projectile = projectile_scene.instantiate() as MagicMissileProjectile
	projectile.global_position = global_position
	projectile.direction = (target_pos - global_position).normalized()
	projectile.damage = damage * might_multiplier
	if is_evolved:
		projectile.modulate = Color(1.0, 0.9, 0.2, 1.0) # 황금빛 탄환
		projectile.speed = 650.0
	
	# 월드 씬 루트에 추가
	get_tree().current_scene.add_child(projectile)
