extends Control
class_name LevelUpUI

@export var card_scene: PackedScene = preload("res://scenes/ui/UpgradeCard.tscn")

@onready var title_label: Label = $Panel/MarginContainer/VBoxContainer/TitleLabel
@onready var cards_container: HBoxContainer = $Panel/MarginContainer/VBoxContainer/CardsContainer

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false
	EventBus.level_up.connect(_on_level_up)

func _on_level_up(new_level: int) -> void:
	title_label.text = "LEVEL UP! (Lv. %d)" % new_level
	
	# 기존 카드 정리
	for child in cards_container.get_children():
		child.queue_free()
		
	var player = get_tree().get_first_node_in_group("Player") as Player
	var pool: Array[Dictionary] = []
	
	if is_instance_valid(player) and player.has_node("InventoryManager"):
		var inv = player.get_node("InventoryManager") as InventoryManager
		pool = inv.get_available_upgrades()
	else:
		# 인벤토리 매니저 부재 시 기본 풀
		pool = [
			{"id": "weapon_magic_missile", "title": "매직 미사일", "description": "기본 공격력 +12", "icon_color": Color(0.2, 0.85, 1.0)},
			{"id": "passive_swift_boots", "title": "신속의 장화", "description": "이동 속도 +12%", "icon_color": Color(0.35, 1.0, 0.45)},
			{"id": "passive_might", "title": "시금치", "description": "전체 공격력 +10%", "icon_color": Color(0.2, 0.9, 0.3)}
		]
		
	var pool_copy = pool.duplicate()
	pool_copy.shuffle()
	var selected_options = pool_copy.slice(0, min(3, pool_copy.size()))
	
	for opt in selected_options:
		var card = card_scene.instantiate() as UpgradeCard
		cards_container.add_child(card)
		card.setup(opt)
		card.card_selected.connect(_on_card_selected)
		
	visible = true
	get_tree().paused = true

func _on_card_selected(upgrade_data: Dictionary) -> void:
	var player = get_tree().get_first_node_in_group("Player") as Player
	if is_instance_valid(player):
		player.apply_upgrade(upgrade_data.get("id", ""))
		
	visible = false
	get_tree().paused = false
