extends Area2D
class_name EnemyProjectile

@export var speed: float = 380.0
@export var damage: float = 15.0
@export var lifetime: float = 4.0

var direction: Vector2 = Vector2.RIGHT

func _ready() -> void:
	add_to_group("EnemyHitbox")
	var timer = get_tree().create_timer(lifetime)
	timer.timeout.connect(queue_free)
	
	area_entered.connect(_on_area_entered)
	rotation = direction.angle()

func _physics_process(delta: float) -> void:
	position += direction * speed * delta

func _on_area_entered(area: Area2D) -> void:
	# 플레이어 Hurtbox 감지
	var player: Player = null
	if area.owner is Player:
		player = area.owner as Player
	elif area.get_parent() is Player:
		player = area.get_parent() as Player
		
	if player:
		player.take_damage(damage)
		_destroy()

func _destroy() -> void:
	set_deferred("monitoring", false)
	set_deferred("monitorable", false)
	queue_free()
