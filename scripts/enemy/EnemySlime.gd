extends CharacterBody2D
class_name EnemySlime

@export var speed: float = 95.0
@export var max_hp: float = 30.0
@export var damage: float = 10.0
@export var exp_value: int = 1

var current_hp: float = 30.0
var player: Node2D = null
var is_dead: bool = false

@onready var visuals: Node2D = $Visuals
@onready var sprite: Sprite2D = $Visuals/Sprite2D

func _ready() -> void:
	current_hp = max_hp
	add_to_group("Enemy")
	
	# 플레이어 노드 참조 찾기
	player = get_tree().get_first_node_in_group("Player")

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

func take_damage(amount: float) -> void:
	if is_dead:
		return
		
	current_hp -= amount
	DamageNumber.spawn(get_tree(), global_position, amount)
	AudioManager.play_hit()
	
	# 피격 피드백 (흰색 플래시)
	var original_color = Color(0.35, 0.9, 0.45, 1.0)
	var tween = create_tween()
	sprite.modulate = Color.WHITE
	tween.tween_property(sprite, "modulate", original_color, 0.1)
	
	# 약한 넉백 효과
	if is_instance_valid(player):
		var knockback_dir = player.global_position.direction_to(global_position)
		global_position += knockback_dir * 12.0
		
	if current_hp <= 0.0:
		die()

func die() -> void:
	if is_dead:
		return
	is_dead = true
	remove_from_group("Enemy")
	
	# 물리 충돌 비활성화 (지연 처리로 물리 쿼리 플러시 오류 방지)
	$CollisionShape2D.set_deferred("disabled", true)
	if has_node("Hurtbox/CollisionShape2D"):
		$Hurtbox/CollisionShape2D.set_deferred("disabled", true)
	if has_node("Hitbox/CollisionShape2D"):
		$Hitbox/CollisionShape2D.set_deferred("disabled", true)
	
	EventBus.enemy_died.emit(global_position, exp_value)
	
	# 사망 애니메이션 (수축하며 페이드아웃)
	var tween = create_tween()
	tween.tween_property(visuals, "scale", Vector2.ZERO, 0.15)
	tween.tween_callback(queue_free)
