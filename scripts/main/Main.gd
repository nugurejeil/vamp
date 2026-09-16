extends Node2D

@export var gem_scene: PackedScene = preload("res://scenes/drop/ExpGem.tscn")

@onready var player: Player = $Player
@onready var spawner: EnemySpawner = $EnemySpawner
@onready var hp_label: Label = $CanvasLayer/HUD/MarginContainer/VBoxContainer/HPLabel
@onready var kill_label: Label = $CanvasLayer/HUD/MarginContainer/VBoxContainer/KillLabel
@onready var enemy_count_label: Label = $CanvasLayer/HUD/MarginContainer/VBoxContainer/EnemyCountLabel

# 상단 진행도 및 타이머 UI
@onready var exp_bar: ProgressBar = $CanvasLayer/HUD/TopBar/ExpProgressBar
@onready var level_label: Label = $CanvasLayer/HUD/TopBar/LevelLabel
@onready var timer_label: Label = $CanvasLayer/HUD/TopBar/TimerLabel

var kill_count: int = 0

func _ready() -> void:
	# 시그널 연결
	EventBus.player_damaged.connect(_on_player_damaged)
	EventBus.player_healed.connect(_on_player_healed)
	EventBus.enemy_died.connect(_on_enemy_died)
	EventBus.exp_gained.connect(_on_exp_gained)
	EventBus.level_up.connect(_on_level_up)
	
	if spawner:
		spawner.time_updated.connect(_on_time_updated)
	
	_update_hp_ui(player.current_hp, player.max_hp)
	_update_kill_ui()
	_update_level_ui(player.level)
	_on_exp_gained(player.current_exp, player.max_exp)

func _process(_delta: float) -> void:
	var enemy_count = get_tree().get_nodes_in_group("Enemy").size()
	enemy_count_label.text = "Enemies Alive: %d" % enemy_count

func _on_time_updated(time_str: String) -> void:
	if timer_label:
		timer_label.text = time_str

func _on_player_damaged(current_hp: float, max_hp: float) -> void:
	_update_hp_ui(current_hp, max_hp)

func _on_player_healed(current_hp: float, max_hp: float) -> void:
	_update_hp_ui(current_hp, max_hp)

func _update_hp_ui(current: float, maximum: float) -> void:
	hp_label.text = "HP: %d / %d" % [int(current), int(maximum)]

func _on_enemy_died(pos: Vector2, exp_val: int) -> void:
	kill_count += 1
	_update_kill_ui()
	_spawn_exp_gem(pos, exp_val)

func _spawn_exp_gem(pos: Vector2, exp_val: int) -> void:
	if gem_scene == null:
		return
	var gem = gem_scene.instantiate() as ExpGem
	gem.global_position = pos
	gem.exp_amount = exp_val
	# 물리 충돌 쿼리 플러시 중 add_child 호출로 인한 PhysicsServer2D 오류 방지
	add_child.call_deferred(gem)

func _update_kill_ui() -> void:
	kill_label.text = "Kills: %d" % kill_count

func _on_exp_gained(cur_exp: int, max_exp: int) -> void:
	if exp_bar:
		exp_bar.max_value = max_exp
		exp_bar.value = cur_exp

func _on_level_up(new_level: int) -> void:
	_update_level_ui(new_level)

func _update_level_ui(lvl: int) -> void:
	if level_label:
		level_label.text = "Lv. %d" % lvl
