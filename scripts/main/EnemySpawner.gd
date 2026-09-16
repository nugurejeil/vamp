extends Node2D
class_name EnemySpawner

signal time_updated(formatted_time: String)

@export var slime_scene: PackedScene = preload("res://scenes/enemy/EnemySlime.tscn")
@export var bat_scene: PackedScene = preload("res://scenes/enemy/EnemyBat.tscn")
@export var elite_scene: PackedScene = preload("res://scenes/enemy/EnemyElite.tscn")
@export var boss_scene: PackedScene = preload("res://scenes/enemy/EnemyBoss.tscn")

@export var spawn_distance: float = 1150.0
@export var max_enemies: int = 250

var game_time: float = 0.0
var player: Node2D = null

# 엘리트 및 보스 스폰 플래그
var elite_early_spawned: bool = false
var boss_1min_spawned: bool = false

@onready var spawn_timer: Timer = $SpawnTimer

func _ready() -> void:
	player = get_tree().get_first_node_in_group("Player")
	spawn_timer.wait_time = 0.8
	spawn_timer.timeout.connect(_on_spawn_timer_timeout)
	spawn_timer.start()

func _process(delta: float) -> void:
	game_time += delta
	var minutes = int(game_time) / 60
	var seconds = int(game_time) % 60
	time_updated.emit("%02d:%02d" % [minutes, seconds])
	
	_check_timed_events()

func _check_timed_events() -> void:
	# 25초: 엘리트 몬스터 출현 (보물 상자 및 진화 기회)
	if game_time >= 25.0 and not elite_early_spawned:
		elite_early_spawned = true
		_spawn_specific_enemy(elite_scene)
		
	# 60초 (1분): 진정한 강력한 보스 출현!
	if game_time >= 60.0 and not boss_1min_spawned:
		boss_1min_spawned = true
		_spawn_specific_enemy(boss_scene)
		EventBus.boss_spawned.emit()

func _on_spawn_timer_timeout() -> void:
	if not is_instance_valid(player):
		player = get_tree().get_first_node_in_group("Player")
		if not is_instance_valid(player):
			return
			
	# 1분 보스전에 맞춘 빠른 웨이브 압축
	if game_time < 20.0:
		spawn_timer.wait_time = 0.8
	elif game_time < 40.0:
		spawn_timer.wait_time = 0.55
	else:
		spawn_timer.wait_time = 0.35
		
	var current_enemies = get_tree().get_nodes_in_group("Enemy").size()
	if current_enemies >= max_enemies:
		return
		
	# 20초 이후부터 박쥐 혼합 등장
	var scene_to_spawn = slime_scene
	if game_time >= 20.0:
		if randf() < 0.45:
			scene_to_spawn = bat_scene
			
	_spawn_specific_enemy(scene_to_spawn)

func _spawn_specific_enemy(scene: PackedScene) -> void:
	if scene == null or not is_instance_valid(player):
		return
		
	var random_angle = randf() * TAU
	var spawn_offset = Vector2(cos(random_angle), sin(random_angle)) * spawn_distance
	var spawn_pos = player.global_position + spawn_offset
	
	var enemy = scene.instantiate() as Node2D
	enemy.global_position = spawn_pos
	
	get_tree().current_scene.add_child.call_deferred(enemy)
	EventBus.enemy_spawned.emit(enemy)
