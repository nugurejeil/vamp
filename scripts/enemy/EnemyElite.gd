extends CharacterBody2D
class_name EnemyElite

@export var speed: float = 75.0
@export var max_hp: float = 350.0
@export var damage: float = 20.0
@export var exp_value: int = 15
@export var chest_scene: PackedScene = preload("res://scenes/drop/TreasureChest.tscn")

var current_hp: float = 350.0
var player: Node2D = null
var is_dead: bool = false

@onready var visuals: Node2D = $Visuals
@onready var sprite: Sprite2D = $Visuals/Sprite2D

func _ready() -> void:
	current_hp = max_hp
	add_to_group("Enemy")
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
	var original_color = Color(1.0, 0.2, 0.2, 1.0)
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
	
	$CollisionShape2D.set_deferred("disabled", true)
	if has_node("Hurtbox/CollisionShape2D"):
		$Hurtbox/CollisionShape2D.set_deferred("disabled", true)
	if has_node("Hitbox/CollisionShape2D"):
		$Hitbox/CollisionShape2D.set_deferred("disabled", true)
		
	# 보물 상자 드롭
	if chest_scene:
		var chest = chest_scene.instantiate() as Node2D
		chest.global_position = global_position
		get_tree().current_scene.add_child.call_deferred(chest)
		
	EventBus.enemy_died.emit(global_position, exp_value)
	
	var tween = create_tween()
	tween.tween_property(visuals, "scale", Vector2.ZERO, 0.25)
	tween.tween_callback(queue_free)
