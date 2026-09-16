extends Control
class_name ChestRewardUI

@onready var title_label: Label = $Panel/MarginContainer/VBoxContainer/TitleLabel
@onready var item_name_label: Label = $Panel/MarginContainer/VBoxContainer/ItemNameLabel
@onready var desc_label: Label = $Panel/MarginContainer/VBoxContainer/DescLabel
@onready var confirm_button: Button = $Panel/MarginContainer/VBoxContainer/ConfirmButton

var inventory_manager: InventoryManager = null

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false
	EventBus.chest_opened.connect(_on_chest_opened)
	confirm_button.pressed.connect(_on_confirm_pressed)

func _on_chest_opened() -> void:
	var player = get_tree().get_first_node_in_group("Player") as Player
	if is_instance_valid(player) and player.has_node("InventoryManager"):
		inventory_manager = player.get_node("InventoryManager") as InventoryManager
		
	if inventory_manager == null:
		return
		
	# 진화 가능 여부 확인
	var evolution = inventory_manager.get_eligible_evolution()
	if evolution.size() > 0:
		title_label.text = "⚡ WEAPON EVOLUTION! ⚡"
		title_label.modulate = Color(1.0, 0.9, 0.2, 1.0)
		item_name_label.text = evolution["title"]
		desc_label.text = evolution["description"]
		inventory_manager.evolve_weapon(evolution["base_weapon_id"])
	else:
		# 일반 보너스 (보유 장비 1종 즉시 강화)
		var upgraded = false
		for wid in inventory_manager.equipped_weapons:
			var w = inventory_manager.equipped_weapons[wid]
			if w["level"] < 8 and not w["is_evolved"]:
				inventory_manager.apply_upgrade(wid)
				var wdata = inventory_manager.weapon_db[wid]
				title_label.text = "🎁 TREASURE CHEST BONUS!"
				title_label.modulate = Color(0.3, 0.9, 1.0, 1.0)
				item_name_label.text = "%s (Lv. %d)" % [wdata["title"], w["level"]]
				desc_label.text = "보물 상자 효과로 레벨이 즉시 1 상승했습니다!"
				upgraded = true
				break
				
		if not upgraded:
			title_label.text = "💰 TREASURE GOLD!"
			title_label.modulate = Color(1.0, 0.85, 0.3, 1.0)
			item_name_label.text = "+500 GOLD"
			desc_label.text = "대량의 황금을 획득하였습니다!"
			
	visible = true
	get_tree().paused = true

func _on_confirm_pressed() -> void:
	visible = false
	get_tree().paused = false
