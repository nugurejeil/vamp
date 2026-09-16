extends Node2D
class_name WeaponGarlic

@export var damage: float = 12.0
@export var radius: float = 220.0
@export var pulse_interval: float = 0.45

var might_multiplier: float = 1.0
var cooldown_multiplier: float = 1.0
var is_evolved: bool = false
var enemies_hit_counter: int = 0

@onready var aura_area: Area2D = $AuraArea
@onready var aura_shape: CollisionShape2D = $AuraArea/CollisionShape2D
@onready var aura_sprite: Sprite2D = $AuraArea/Sprite2D
@onready var pulse_timer: Timer = $PulseTimer

func _ready() -> void:
	_update_shape()
	pulse_timer.wait_time = pulse_interval
	pulse_timer.timeout.connect(_on_pulse_timeout)
	pulse_timer.start()

func apply_level(lvl: int) -> void:
	damage = 12.0 + (lvl - 1) * 4.0
	radius = 220.0 + (lvl - 1) * 24.0
	pulse_interval = max(0.2, 0.45 - (lvl - 1) * 0.03)
	pulse_timer.wait_time = max(0.15, pulse_interval * cooldown_multiplier)
	_update_shape()

func evolve() -> void:
	is_evolved = true
	damage = 32.0
	radius = 360.0
	pulse_interval = 0.25
	pulse_timer.wait_time = max(0.12, pulse_interval * cooldown_multiplier)
	aura_sprite.modulate = Color(0.6, 0.1, 0.9, 0.35) # 다크 바이올렛 소울 이터
	_update_shape()

func _update_shape() -> void:
	if aura_shape and aura_shape.shape is CircleShape2D:
		(aura_shape.shape as CircleShape2D).radius = radius
	if aura_sprite:
		var scale_factor = (radius / 64.0)
		aura_sprite.scale = Vector2(scale_factor, scale_factor)

func _on_pulse_timeout() -> void:
	var overlapping_areas = aura_area.get_overlapping_areas()
	var hit_any = false
	
	for area in overlapping_areas:
		if area.is_in_group("EnemyHurtbox"):
			var enemy = area.owner if area.owner else area.get_parent()
			if enemy and enemy.has_method("take_damage") and not enemy.get("is_dead"):
				enemy.take_damage(damage * might_multiplier)
				hit_any = true
				if is_evolved:
					enemies_hit_counter += 1
					if enemies_hit_counter >= 4:
						enemies_hit_counter = 0
						var player = get_tree().get_first_node_in_group("Player")
						if player and player.has_method("heal"):
							player.heal(1.0)
	
	if hit_any:
		# 펄스 팽창 시각 피드백
		var tween = create_tween()
		tween.tween_property(aura_sprite, "scale", aura_sprite.scale * 1.08, 0.06)
		tween.tween_property(aura_sprite, "scale", aura_sprite.scale, 0.06)
