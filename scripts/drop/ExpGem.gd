extends Area2D
class_name ExpGem

@export var exp_amount: int = 1
@export var base_speed: float = 120.0
@export var acceleration: float = 850.0

var is_attracted: bool = false
var target_player: Node2D = null
var current_speed: float = 0.0

@onready var visuals: Node2D = $Visuals

func _ready() -> void:
	add_to_group("ExpGem")
	current_speed = base_speed
	
	# 부유 애니메이션 (바닥에 있을 때 가볍게 위아래로 움직임)
	var tween = create_tween().set_loops()
	tween.tween_property(visuals, "position:y", -3.0, 0.6).set_trans(Tween.TRANS_SINE)
	tween.tween_property(visuals, "position:y", 3.0, 0.6).set_trans(Tween.TRANS_SINE)

func start_attract(player: Node2D) -> void:
	if is_attracted:
		return
	is_attracted = true
	target_player = player

func _physics_process(delta: float) -> void:
	if not is_attracted:
		return
		
	if not is_instance_valid(target_player):
		is_attracted = false
		return
		
	current_speed += acceleration * delta
	var direction = global_position.direction_to(target_player.global_position)
	global_position += direction * current_speed * delta
	
	# 플레이어와 충분히 가까워지면 수집 완료
	if global_position.distance_to(target_player.global_position) <= 35.0:
		_collect()

func _collect() -> void:
	AudioManager.play_gem()
	if is_instance_valid(target_player) and target_player.has_method("gain_exp"):
		target_player.gain_exp(exp_amount)
		
	# 가벼운 수축 페이드아웃 효과 후 제거
	var tween = create_tween()
	tween.tween_property(visuals, "scale", Vector2.ZERO, 0.1)
	tween.tween_callback(queue_free)
