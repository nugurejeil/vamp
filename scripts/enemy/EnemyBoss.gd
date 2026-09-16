extends CharacterBody2D
class_name EnemyBoss

@export var speed: float = 120.0
@export var max_hp: float = 1800.0
@export var damage: float = 25.0
@export var exp_value: int = 80

@export var projectile_scene: PackedScene = preload("res://scenes/enemy/EnemyProjectile.tscn")
@export var chest_scene: PackedScene = preload("res://scenes/drop/TreasureChest.tscn")

var current_hp: float = 1800.0
var player: Node2D = null
var is_dead: bool = false

@onready var visuals: Node2D = $Visuals
@onready var sprite: Sprite2D = $Visuals/Sprite2D
@onready var hp_bar: ProgressBar = $HPBar
@onready var radial_timer: Timer = $RadialAttackTimer
@onready var burst_timer: Timer = $BurstAttackTimer

func _ready() -> void:
	current_hp = max_hp
	add_to_group("Enemy")
	player = get_tree().get_first_node_in_group("Player")
	
	hp_bar.max_value = max_hp
	hp_bar.value = current_hp
	
	# 공격 타이머 연결
	radial_timer.timeout.connect(_fire_radial_attack)
	burst_timer.timeout.connect(_fire_burst_attack)
	radial_timer.start()
	burst_timer.start()
	
	# 보스 등장 시 카메라 셰이크
	if is_instance_valid(player) and player.has_method("add_shake"):
		player.add_shake(0.8)

func _physics_process(_delta: float) -> void:
	if is_dead:
		return
		
	if not is_instance_valid(player):
		player = get_tree().get_first_node_in_group("Player")
		if not is_instance_valid(player):
			return
			
	var dir = global_position.direction_to(player.global_position)
	velocity = dir * speed
	move_and_slide()
	
	if dir.x > 0:
		visuals.scale.x = 1.0
	elif dir.x < 0:
		visuals.scale.x = -1.0

# 1. 사방으로 퍼져나가는 12방향 탄막 공격
func _fire_radial_attack() -> void:
	if is_dead or projectile_scene == null:
		return
		
	var count = 12
	var angle_step = TAU / count
	for i in range(count):
		var angle = angle_step * i
		var dir = Vector2(cos(angle), sin(angle))
		_spawn_projectile(dir)

# 2. 플레이어를 향해 발사되는 직선 3연발 공격
func _fire_burst_attack() -> void:
	if is_dead or projectile_scene == null or not is_instance_valid(player):
		return
		
	for i in range(3):
		get_tree().create_timer(i * 0.14).timeout.connect(func():
			if is_instance_valid(self) and not is_dead and is_instance_valid(player):
				var aim_dir = global_position.direction_to(player.global_position)
				_spawn_projectile(aim_dir)
		)

func _spawn_projectile(dir: Vector2) -> void:
	if projectile_scene == null:
		return
	var proj = projectile_scene.instantiate() as EnemyProjectile
	proj.position = global_position
	proj.direction = dir
	if get_parent():
		get_parent().add_child.call_deferred(proj)
	elif get_tree() and get_tree().current_scene:
		get_tree().current_scene.add_child.call_deferred(proj)

func take_damage(amount: float) -> void:
	if is_dead:
		return
		
	current_hp -= amount
	hp_bar.value = current_hp
	DamageNumber.spawn(get_tree(), global_position, amount)
	AudioManager.play_hit()
	
	var original_color = Color(0.85, 0.15, 0.25, 1.0)
	var tween = create_tween()
	sprite.modulate = Color.WHITE
	tween.tween_property(sprite, "modulate", original_color, 0.08)
	
	if current_hp <= 0.0:
		die()

func die() -> void:
	if is_dead:
		return
	is_dead = true
	remove_from_group("Enemy")
	
	radial_timer.stop()
	burst_timer.stop()
	hp_bar.visible = false
	
	$CollisionShape2D.set_deferred("disabled", true)
	if has_node("Hurtbox/CollisionShape2D"):
		$Hurtbox/CollisionShape2D.set_deferred("disabled", true)
	if has_node("Hitbox/CollisionShape2D"):
		$Hitbox/CollisionShape2D.set_deferred("disabled", true)
		
	# 보스 사망 시 큰 카메라 흔들림
	if is_instance_valid(player) and player.has_method("add_shake"):
		player.add_shake(1.0)
		
	# 황금 보물 상자 드롭
	if chest_scene:
		var chest = chest_scene.instantiate() as Node2D
		chest.position = global_position
		if get_parent():
			get_parent().add_child.call_deferred(chest)
		elif get_tree() and get_tree().current_scene:
			get_tree().current_scene.add_child.call_deferred(chest)
		
	EventBus.enemy_died.emit(global_position, exp_value)
	
	# 사망 후 승리 모달 호출 (1.5초 딜레이)
	get_tree().create_timer(1.5).timeout.connect(func():
		var victory_ui = get_tree().current_scene.get_node_or_null("CanvasLayer/VictoryGameOverUI")
		if victory_ui and victory_ui.has_method("show_results"):
			victory_ui.show_results(true)
	)
	
	var tween = create_tween()
	tween.tween_property(visuals, "scale", Vector2.ZERO, 0.35)
	tween.tween_callback(queue_free)
