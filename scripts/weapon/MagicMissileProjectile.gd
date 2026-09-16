extends Area2D
class_name MagicMissileProjectile

@export var speed: float = 480.0
@export var damage: float = 25.0
@export var pierce: int = 1
@export var lifetime: float = 3.0

var direction: Vector2 = Vector2.RIGHT

func _ready() -> void:
	# 수명 타이머 설정
	var timer := get_tree().create_timer(lifetime)
	timer.timeout.connect(queue_free)
	
	area_entered.connect(_on_area_entered)
	rotation = direction.angle()

func _physics_process(delta: float) -> void:
	position += direction * speed * delta

func _on_area_entered(area: Area2D) -> void:
	if area.is_in_group("EnemyHurtbox"):
		var enemy = area.owner if area.owner else area.get_parent()
		if enemy and enemy.has_method("take_damage"):
			enemy.take_damage(damage)
			pierce -= 1
			if pierce <= 0:
				set_deferred("monitoring", false)
				set_deferred("monitorable", false)
				queue_free()
