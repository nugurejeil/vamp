extends CharacterBody2D
class_name Player

@export var speed: float = 220.0
@export var max_hp: float = 100.0
@export var invulnerability_duration: float = 0.4
@export var pickup_radius: float = 240.0
@export var walk_anim_speed: float = 10.0 # 초당 걷기 애니메이션 프레임 속도

var current_hp: float = 100.0
var is_invulnerable: bool = false

# 애니메이션 트랙 변수
var anim_timer: float = 0.0
var anim_frame: int = 0
var current_dir_row: int = 0 # 0: Down, 1: Left, 2: Right, 3: Up

# 레벨 및 경험치 스탯
var level: int = 1
var current_exp: int = 0
var max_exp: int = 5

@onready var visuals: Node2D = $Visuals
@onready var sprite: Sprite2D = $Visuals/Sprite2D
@onready var invuln_timer: Timer = $InvulnerabilityTimer
@onready var camera: Camera2D = $Camera2D
@onready var pickup_area: Area2D = $PickupArea
@onready var pickup_shape: CollisionShape2D = $PickupArea/CollisionShape2D
@onready var inventory: InventoryManager = $InventoryManager

func _ready() -> void:
	current_hp = max_hp
	invuln_timer.wait_time = invulnerability_duration
	invuln_timer.one_shot = true
	invuln_timer.timeout.connect(_on_invulnerability_timeout)
	
	# Hurtbox 피격 감지 연결
	var hurtbox: Area2D = $Hurtbox
	hurtbox.area_entered.connect(_on_hurtbox_area_entered)
	
	# PickupArea 자석 반경 설정 및 감지 연결
	_update_pickup_radius(pickup_radius)
	pickup_area.area_entered.connect(_on_pickup_area_entered)
	
	# 인벤토리 매니저 초기화
	if inventory:
		inventory.setup(self)
	
	# 초기 경험치 신호 전달
	EventBus.exp_gained.emit(current_exp, max_exp)

func _physics_process(delta: float) -> void:
	var move_dir := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	velocity = move_dir * speed
	move_and_slide()
	
	_update_animation(move_dir, delta)

func _update_animation(move_dir: Vector2, delta: float) -> void:
	if move_dir != Vector2.ZERO:
		# 기본 스프라이트가 '좌측'을 향하고 있으므로:
		# 우측 이동(x > 0) 시 -1.0으로 이미지 반전 (우측을 바라봄)
		# 좌측 이동(x < 0) 시 1.0으로 정방향 (좌측을 바라봄)
		if move_dir.x > 0:
			visuals.scale.x = -1.0
		elif move_dir.x < 0:
			visuals.scale.x = 1.0

		# 상하/좌우 주요 이동 축 판별 (앞뒤 애니메이션 행 반전 적용)
		if abs(move_dir.x) > abs(move_dir.y):
			if move_dir.x > 0:
				current_dir_row = 2 # 우측
			else:
				current_dir_row = 1 # 좌측
		else:
			if move_dir.y > 0:
				current_dir_row = 3 # 하단/정면
			else:
				current_dir_row = 0 # 상단/후면
		
		# 걷기 애니메이션 프레임 순환
		anim_timer += delta * walk_anim_speed
		anim_frame = int(anim_timer) % 4
	else:
		# 정지 상태: 서있는 프레임 고정
		anim_timer = 0.0
		anim_frame = 0
		
	if sprite:
		sprite.frame = current_dir_row * 4 + anim_frame

var shake_trauma: float = 0.0

func _process(delta: float) -> void:
	if shake_trauma > 0.0:
		shake_trauma = max(0.0, shake_trauma - delta * 2.2)
		var shake_offset = shake_trauma * shake_trauma * 22.0
		camera.offset = Vector2(randf_range(-shake_offset, shake_offset), randf_range(-shake_offset, shake_offset))
	elif camera.offset != Vector2.ZERO:
		camera.offset = Vector2.ZERO

func add_shake(amount: float) -> void:
	shake_trauma = clamp(shake_trauma + amount, 0.0, 1.0)

func take_damage(amount: float) -> void:
	if is_invulnerable or current_hp <= 0:
		return
		
	add_shake(0.55)
	current_hp = max(0.0, current_hp - amount)
	EventBus.player_damaged.emit(current_hp, max_hp)
	
	if current_hp <= 0:
		die()
	else:
		start_invulnerability()

func heal(amount: float) -> void:
	if current_hp <= 0:
		return
	current_hp = min(max_hp, current_hp + amount)
	EventBus.player_healed.emit(current_hp, max_hp)
	
	# 회복 초록 플래시 연출
	var tween = create_tween()
	sprite.modulate = Color(0.3, 1.0, 0.4, 1.0)
	tween.tween_property(sprite, "modulate", Color(1, 1, 1, 1), 0.2)

func gain_exp(amount: int) -> void:
	current_exp += amount
	EventBus.exp_gained.emit(current_exp, max_exp)
	
	# 경험치 완충 시 레벨업 처리
	while current_exp >= max_exp:
		current_exp -= max_exp
		level += 1
		max_exp = int(max_exp * 1.35) + 4
		EventBus.level_up.emit(level)
		EventBus.exp_gained.emit(current_exp, max_exp)

func apply_upgrade(upgrade_id: String) -> void:
	if inventory:
		inventory.apply_upgrade(upgrade_id)

func _update_pickup_radius(new_radius: float) -> void:
	pickup_radius = new_radius
	if pickup_shape and pickup_shape.shape is CircleShape2D:
		(pickup_shape.shape as CircleShape2D).radius = pickup_radius

func start_invulnerability() -> void:
	is_invulnerable = true
	invuln_timer.start()
	
	# 피격 깜빡임 트윈 (Flash Effect)
	var tween = create_tween().set_loops(4)
	tween.tween_property(sprite, "modulate:a", 0.3, 0.05)
	tween.tween_property(sprite, "modulate:a", 1.0, 0.05)

func _on_invulnerability_timeout() -> void:
	is_invulnerable = false
	sprite.modulate.a = 1.0

func die() -> void:
	EventBus.player_died.emit()
	set_physics_process(false)
	var tween = create_tween()
	tween.tween_property(sprite, "modulate:a", 0.0, 0.5)
	tween.parallel().tween_property(visuals, "scale", Vector2.ZERO, 0.5)

func _on_hurtbox_area_entered(area: Area2D) -> void:
	if area.is_in_group("EnemyHitbox"):
		var damage = area.get("damage")
		if damage == null:
			damage = 10.0
		take_damage(damage)

func _on_pickup_area_entered(area: Area2D) -> void:
	if area.is_in_group("ExpGem") and area.has_method("start_attract"):
		area.start_attract(self)
