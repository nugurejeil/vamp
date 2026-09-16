extends Button
class_name UpgradeCard

signal card_selected(upgrade_data: Dictionary)

var upgrade_data: Dictionary = {}

@onready var title_label: Label = $MarginContainer/VBoxContainer/TitleLabel
@onready var desc_label: Label = $MarginContainer/VBoxContainer/DescLabel
@onready var icon_rect: ColorRect = $MarginContainer/VBoxContainer/IconCenter/IconRect

func setup(data: Dictionary) -> void:
	upgrade_data = data
	title_label.text = data.get("title", "Upgrade")
	desc_label.text = data.get("description", "")
	if data.has("icon_color"):
		icon_rect.color = data["icon_color"]

func _pressed() -> void:
	card_selected.emit(upgrade_data)
