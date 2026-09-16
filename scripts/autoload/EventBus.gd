extends Node

## 전역 이벤트 버스 (Autoload)
## 게임 내 객체 간 결합도를 낮추기 위해 시그널을 중계하고 공통 입력을 설정합니다.

# 적 관련 이벤트
signal enemy_spawned(enemy: Node2D)
signal enemy_died(enemy_position: Vector2, exp_value: int)

# 플레이어 관련 이벤트
signal player_damaged(current_hp: float, max_hp: float)
signal player_healed(current_hp: float, max_hp: float)
signal player_died()

# 레벨업 및 보상 이벤트
signal exp_gained(current_exp: int, max_exp: int)
signal level_up(new_level: int)
signal chest_opened()
signal boss_spawned()

func _ready() -> void:
	_ensure_input_mappings()

func _ensure_input_mappings() -> void:
	var mappings = {
		"move_left": [KEY_A, KEY_LEFT],
		"move_right": [KEY_D, KEY_RIGHT],
		"move_up": [KEY_W, KEY_UP],
		"move_down": [KEY_S, KEY_DOWN]
	}
	
	for action in mappings:
		if not InputMap.has_action(action):
			InputMap.add_action(action)
		for key in mappings[action]:
			var ev = InputEventKey.new()
			ev.physical_keycode = key
			if not InputMap.action_has_event(action, ev):
				InputMap.action_add_event(action, ev)
