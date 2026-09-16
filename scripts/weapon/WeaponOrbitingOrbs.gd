extends Node2D
class_name WeaponOrbitingOrbs

@export var base_damage: float = 20.0
@export var orbit_radius: float = 220.0
@export var orbit_speed: float = 3.2
@export var orb_count: int = 2
@export var duration: float = 4.5
@export var cooldown: float = 3.0

var might_multiplier: float = 1.0
var cooldown_multiplier: float = 1.0
var is_evolved: bool = false
var current_angle: float = 0.0
var is_active: bool = true

var orbs: Array[Area2D] = []
@onready var orbs_container: Node2D = $OrbsContainer
@onready var state_timer: Timer = $StateTimer

func _ready() -> void:
	_create_orbs()
	state_timer.timeout.connect(_on_state_timer_timeout)
	state_timer.wait_time = duration
	state_timer.start()

func apply_level(lvl: int) -> void:
	base_damage = 20.0 + (lvl - 1) * 6.0
	if lvl >= 3: orb_count = 3
	if lvl >= 6: orb_count = 4
	orbit_speed = 3.2 + (lvl - 1) * 0.3
	_create_orbs()

func evolve() -> void:
	is_evolved = true
	orb_count = 5
	base_damage = 45.0
	orbit_speed = 6.0
	is_active = true
	state_timer.stop() # 진화 시 영구 지속
	_create_orbs()

func _create_orbs() -> void:
	# 기존 오브 정리
	for orb in orbs:
		if is_instance_valid(orb):
			orb.queue_free()
	orbs.clear()
	
	for i in range(orb_count):
		var orb = Area2D.new()
		orb.collision_layer = 8
		orb.collision_mask = 16
		orb.add_to_group("PlayerProjectile")
		
		# 충돌 셰이프
		var col = CollisionShape2D.new()
		var shape = CircleShape2D.new()
		shape.radius = 32.0
		col.shape = shape
		orb.add_child(col)
		
		# 비주얼 스프라이트
		var sprite = Sprite2D.new()
		sprite.texture = preload("res://icon.svg")
		sprite.scale = Vector2(0.36, 0.36)
		sprite.modulate = Color(1.0, 0.2, 0.4, 1.0) if is_evolved else Color(0.85, 0.4, 1.0, 1.0)
		orb.add_child(sprite)
		
		orb.area_entered.connect(func(area: Area2D):
			if area.is_in_group("EnemyHurtbox"):
				var enemy = area.owner if area.owner else area.get_parent()
				if enemy and enemy.has_method("take_damage"):
					enemy.take_damage(base_damage * might_multiplier)
		)
		
		orbs_container.add_child(orb)
		orbs.append(orb)

func _physics_process(delta: float) -> void:
	if not is_active:
		return
		
	current_angle += orbit_speed * delta
	var count = orbs.size()
	if count == 0: return
	
	var angle_step = TAU / count
	for i in range(count):
		var orb = orbs[i]
		if is_instance_valid(orb):
			var angle = current_angle + (i * angle_step)
			orb.position = Vector2(cos(angle), sin(angle)) * orbit_radius

func _on_state_timer_timeout() -> void:
	if is_evolved:
		return
		
	is_active = not is_active
	orbs_container.visible = is_active
	for orb in orbs:
		if is_instance_valid(orb):
			orb.monitoring = is_active
			
	if is_active:
		state_timer.wait_time = duration
	else:
		state_timer.wait_time = max(0.5, cooldown * cooldown_multiplier)
	state_timer.start()
