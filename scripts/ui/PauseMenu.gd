extends Control
class_name PauseMenu

@onready var resume_btn: Button = $Panel/MarginContainer/VBoxContainer/ResumeButton
@onready var restart_btn: Button = $Panel/MarginContainer/VBoxContainer/RestartButton
@onready var quit_btn: Button = $Panel/MarginContainer/VBoxContainer/QuitButton

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false
	
	resume_btn.pressed.connect(_on_resume_pressed)
	restart_btn.pressed.connect(_on_restart_pressed)
	quit_btn.pressed.connect(_on_quit_pressed)

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		toggle_pause()

func toggle_pause() -> void:
	# 레벨업 창이나 보물 상자 창이 떠있을 때는 ESC 일시정지 무시
	var level_up_ui = get_tree().get_first_node_in_group("LevelUpUI")
	if level_up_ui and level_up_ui.visible:
		return
		
	var is_paused = not visible
	visible = is_paused
	get_tree().paused = is_paused

func _on_resume_pressed() -> void:
	visible = false
	get_tree().paused = false

func _on_restart_pressed() -> void:
	visible = false
	get_tree().paused = false
	get_tree().reload_current_scene()

func _on_quit_pressed() -> void:
	get_tree().quit()
