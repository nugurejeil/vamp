extends CharacterBody2D
class_name EnemyBat

@export var speed: float = 180.0
@export var max_hp: float = 15.0
@export var damage: float = 8.0
@export var exp_value: int = 1

var current_hp: float = 15.0
var player: Node2D = null
var is_dead: bool = false
var wobble_time: float = 0.0

@onready var visuals: Node2D = $Visuals
@onready var sprite: Sprite2D = $Visuals/Sprite2D

func _ready() -> void:
	current_hp = max_hp
	add_to_group("Enemy")
	player = get_tree().get_first_node_in_group("Player")
	wobble_time = randf() * TAU

func _physics_process(delta: float) -> void:
	if is_dead:
		return
		
	if not is_instance_valid(player):
		player = get_tree().get_first_node_in_group("Player")
		if not is_instance_valid(player):
			return
			
	wobble_time += delta * 8.0
	var to_player = global_position.direction_to(player.global_position)
	var perpendicular = Vector2(-to_player.y, to_player.x) * sin(wobble_time) * 0.4
	
	velocity = (to_player + perpendicular).normalized() * speed
	move_and_slide()
	
	if velocity.x > 0:
		visuals.scale.x = 1.0
	elif velocity.x < 0:
		visuals.scale.x = -1.0

func take_damage(amount: float) -> void:
	if is_dead:
		return
		
	current_hp -= amount
	DamageNumber.spawn(get_tree(), global_position, amount)
	AudioManager.play_hit()
	var orig_color = Color(0.9, 0.3, 0.4, 1.0)
	var tween = create_tween()
	sprite.modulate = Color.WHITE
	tween.tween_property(sprite, "modulate", orig_color, 0.1)
	
	if current_hp <= 0.0:
		die()

func die() -> void:
	if is_dead:
		return
	is_dead = true
	remove_from_group("Enemy")
	
	$CollisionShape2D.set_deferred("disabled", true)
	if has_node("Hurtbox/CollisionShape2D"):
		$Hurtbox/CollisionShape2D.set_deferred("disabled", true)
	if has_node("Hitbox/CollisionShape2D"):
		$Hitbox/CollisionShape2D.set_deferred("disabled", true)
		
	EventBus.enemy_died.emit(global_position, exp_value)
	
	var tween = create_tween()
	tween.tween_property(visuals, "scale", Vector2.ZERO, 0.12)
	tween.tween_callback(queue_free)
