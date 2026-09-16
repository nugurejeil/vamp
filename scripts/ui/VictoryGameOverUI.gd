extends Control
class_name VictoryGameOverUI

@onready var title_label: Label = $Panel/MarginContainer/VBoxContainer/TitleLabel
@onready var time_label: Label = $Panel/MarginContainer/VBoxContainer/StatsGrid/TimeVal
@onready var level_label: Label = $Panel/MarginContainer/VBoxContainer/StatsGrid/LevelVal
@onready var kills_label: Label = $Panel/MarginContainer/VBoxContainer/StatsGrid/KillsVal
@onready var equipment_label: Label = $Panel/MarginContainer/VBoxContainer/EquipmentList
@onready var restart_button: Button = $Panel/MarginContainer/VBoxContainer/RestartButton

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false
	
	EventBus.player_died.connect(_on_player_died)
	restart_button.pressed.connect(_on_restart_pressed)

func show_results(is_victory: bool) -> void:
	if is_victory:
		title_label.text = "🏆 VICTORY! 🏆"
		title_label.add_theme_color_override("font_color", Color(1.0, 0.85, 0.2, 1.0))
	else:
		title_label.text = "💀 GAME OVER 💀"
		title_label.add_theme_color_override("font_color", Color(1.0, 0.3, 0.3, 1.0))
		
	var main = get_tree().current_scene
	if main:
		if "kill_count" in main:
			kills_label.text = "%d" % main.kill_count
		if main.has_node("CanvasLayer/HUD/TopBar/TimerLabel"):
			time_label.text = main.get_node("CanvasLayer/HUD/TopBar/TimerLabel").text
			
	var player = get_tree().get_first_node_in_group("Player") as Player
	if is_instance_valid(player):
		level_label.text = "Lv. %d" % player.level
		if player.has_node("InventoryManager"):
			var inv = player.get_node("InventoryManager") as InventoryManager
			var summary_items = []
			for wid in inv.equipped_weapons:
				var w = inv.equipped_weapons[wid]
				var wname = inv.weapon_db[wid]["title"]
				if w.get("is_evolved"):
					wname = "[진화] " + wname
				summary_items.append("%s (Lv.%d)" % [wname, w["level"]])
			for pid in inv.equipped_passives:
				var p = inv.equipped_passives[pid]
				var pname = inv.passive_db[pid]["title"]
				summary_items.append("%s (Lv.%d)" % [pname, p["level"]])
			equipment_label.text = "장착 장비: " + ", ".join(summary_items)
			
	visible = true
	get_tree().paused = true

func _on_player_died() -> void:
	show_results(false)

func _on_restart_pressed() -> void:
	visible = false
	get_tree().paused = false
	get_tree().reload_current_scene()
