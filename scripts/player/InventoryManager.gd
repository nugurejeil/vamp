extends Node2D
class_name InventoryManager

## 무기 6개 + 패시브 6개 슬롯 및 진화 관리 매니저

const MAX_WEAPONS = 6
const MAX_PASSIVES = 6

# 플레이어 및 무기 참조
var player: Player = null

# 현재 보유 중인 장비 상태: id -> {"level": int, "max_level": int, ...}
var equipped_weapons: Dictionary = {}
var equipped_passives: Dictionary = {}

# 무기 정의 데이터베이스
var weapon_db: Dictionary = {
	"weapon_magic_missile": {
		"id": "weapon_magic_missile",
		"type": "weapon",
		"title": "매직 미사일",
		"description": "가장 가까운 적에게 투사체를 발사합니다.",
		"max_level": 8,
		"scene_path": "res://scenes/weapon/WeaponMagicMissile.tscn",
		"evolves_to": "weapon_holy_wand",
		"required_passive": "passive_empty_tome",
		"icon_color": Color(0.2, 0.85, 1.0)
	},
	"weapon_orbiting_orbs": {
		"id": "weapon_orbiting_orbs",
		"type": "weapon",
		"title": "회전 오브",
		"description": "플레이어 주변을 회전하며 충돌하는 구체를 소환합니다.",
		"max_level": 8,
		"scene_path": "res://scenes/weapon/WeaponOrbitingOrbs.tscn",
		"evolves_to": "weapon_unholy_vespers",
		"required_passive": "passive_might",
		"icon_color": Color(0.9, 0.4, 1.0)
	},
	"weapon_garlic": {
		"id": "weapon_garlic",
		"type": "weapon",
		"title": "마늘 오라",
		"description": "플레이어 주변 영역에 지속 데미지와 넉백 오라를 전개합니다.",
		"max_level": 8,
		"scene_path": "res://scenes/weapon/WeaponGarlic.tscn",
		"evolves_to": "weapon_soul_eater",
		"required_passive": "passive_vitality",
		"icon_color": Color(1.0, 0.95, 0.4)
	},
	"weapon_holy_water": {
		"id": "weapon_holy_water",
		"type": "weapon",
		"title": "성수",
		"description": "적 위치에 성수를 던져 3초간 지속되는 화염 장판을 생성합니다.",
		"max_level": 8,
		"scene_path": "res://scenes/weapon/WeaponHolyWater.tscn",
		"evolves_to": "weapon_la_borra",
		"required_passive": "passive_attractorb",
		"icon_color": Color(0.3, 0.7, 1.0)
	}
}

# 진화 무기 정의
var evolution_db: Dictionary = {
	"weapon_holy_wand": {
		"id": "weapon_holy_wand",
		"title": "[진화] 홀리 완드",
		"description": "딜레이 없이 연속으로 마법 탄환을 쏟아붓습니다.",
		"base_weapon": "weapon_magic_missile"
	},
	"weapon_unholy_vespers": {
		"id": "weapon_unholy_vespers",
		"title": "[진화] 불경한 저녁기도",
		"description": "영구적으로 빠르게 회전하며 절대 방어벽을 형성합니다.",
		"base_weapon": "weapon_orbiting_orbs"
	},
	"weapon_soul_eater": {
		"id": "weapon_soul_eater",
		"title": "[진화] 영혼 흡수기",
		"description": "오라 범위가 극대화되며 적 타격 시 플레이어 체력을 흡혈합니다.",
		"base_weapon": "weapon_garlic"
	},
	"weapon_la_borra": {
		"id": "weapon_la_borra",
		"title": "[진화] 라 보라",
		"description": "성수 화염 장판이 플레이어 쪽으로 모여들며 거대화됩니다.",
		"base_weapon": "weapon_holy_water"
	}
}

# 패시브 정의 데이터베이스
var passive_db: Dictionary = {
	"passive_might": {
		"id": "passive_might",
		"type": "passive",
		"title": "시금치",
		"description": "모든 무기의 공격력이 10% 증가합니다.",
		"max_level": 5,
		"icon_color": Color(0.2, 0.9, 0.3)
	},
	"passive_empty_tome": {
		"id": "passive_empty_tome",
		"type": "passive",
		"title": "빈 책",
		"description": "모든 무기의 쿨다운이 8% 감소합니다.",
		"max_level": 5,
		"icon_color": Color(0.8, 0.85, 0.95)
	},
	"passive_swift_boots": {
		"id": "passive_swift_boots",
		"type": "passive",
		"title": "신속의 장화",
		"description": "플레이어 이동 속도가 12% 증가합니다.",
		"max_level": 5,
		"icon_color": Color(0.3, 1.0, 0.5)
	},
	"passive_attractorb": {
		"id": "passive_attractorb",
		"type": "passive",
		"title": "자석 구슬",
		"description": "아이템 및 경험치 흡수 반경이 30% 증가합니다.",
		"max_level": 5,
		"icon_color": Color(1.0, 0.8, 0.2)
	},
	"passive_vitality": {
		"id": "passive_vitality",
		"type": "passive",
		"title": "붉은 심장",
		"description": "최대 체력이 20 증가하고 체력을 30 회복합니다.",
		"max_level": 5,
		"icon_color": Color(1.0, 0.3, 0.3)
	}
}

# 계산된 전역 보정치
var might_multiplier: float = 1.0
var cooldown_multiplier: float = 1.0
var speed_multiplier: float = 1.0
var pickup_radius_multiplier: float = 1.0

func setup(p_player: Player) -> void:
	player = p_player
	
	# 기본 시작 무기 등록 (매직 미사일)
	var existing_missile = player.get_node_or_null("WeaponMagicMissile")
	if existing_missile:
		equipped_weapons["weapon_magic_missile"] = {
			"level": 1,
			"node": existing_missile,
			"is_evolved": false
		}

# 레벨업 팝업창에 제시할 수 있는 업그레이드 카드 풀 반환
func get_available_upgrades() -> Array[Dictionary]:
	var options: Array[Dictionary] = []
	var weapon_slots_free = equipped_weapons.size() < MAX_WEAPONS
	var passive_slots_free = equipped_passives.size() < MAX_PASSIVES
	
	# 1. 무기 풀 검사
	for wid in weapon_db:
		var wdata = weapon_db[wid]
		if equipped_weapons.has(wid):
			var current_lvl = equipped_weapons[wid]["level"]
			if current_lvl < wdata["max_level"] and not equipped_weapons[wid]["is_evolved"]:
				options.append({
					"id": wid,
					"type": "weapon",
					"title": "%s (Lv. %d)" % [wdata["title"], current_lvl + 1],
					"description": "레벨 %d 강화" % (current_lvl + 1),
					"icon_color": wdata["icon_color"]
				})
		elif weapon_slots_free:
			# 미보유 무기 신규 획득
			options.append({
				"id": wid,
				"type": "weapon",
				"title": "%s (NEW)" % wdata["title"],
				"description": wdata["description"],
				"icon_color": wdata["icon_color"]
			})
			
	# 2. 패시브 풀 검사
	for pid in passive_db:
		var pdata = passive_db[pid]
		if equipped_passives.has(pid):
			var current_lvl = equipped_passives[pid]["level"]
			if current_lvl < pdata["max_level"]:
				options.append({
					"id": pid,
					"type": "passive",
					"title": "%s (Lv. %d)" % [pdata["title"], current_lvl + 1],
					"description": "레벨 %d 강화: %s" % [current_lvl + 1, pdata["description"]],
					"icon_color": pdata["icon_color"]
				})
		elif passive_slots_free:
			# 미보유 패시브 신규 획득
			options.append({
				"id": pid,
				"type": "passive",
				"title": "%s (NEW)" % pdata["title"],
				"description": pdata["description"],
				"icon_color": pdata["icon_color"]
			})
			
	# 기본 회복 카드(옵션이 적을 때 대비)
	options.append({
		"id": "heal_meat",
		"type": "heal",
		"title": "신선한 고기",
		"description": "체력 40을 즉시 회복합니다.",
		"icon_color": Color(1.0, 0.4, 0.4)
	})
	
	return options

# 업그레이드 선택 적용
func apply_upgrade(item_id: String) -> void:
	if item_id == "heal_meat":
		if player: player.heal(40.0)
		return
		
	if weapon_db.has(item_id):
		_upgrade_weapon(item_id)
	elif passive_db.has(item_id):
		_upgrade_passive(item_id)

func _upgrade_weapon(wid: String) -> void:
	var wdata = weapon_db[wid]
	if equipped_weapons.has(wid):
		equipped_weapons[wid]["level"] += 1
		var lvl = equipped_weapons[wid]["level"]
		var node = equipped_weapons[wid]["node"]
		if node and node.has_method("apply_level"):
			node.apply_level(lvl)
		elif node:
			# 기본 스탯 증대
			if "damage" in node: node.damage += 8.0
			if "attack_interval" in node: node.attack_interval = max(0.2, node.attack_interval * 0.9)
	else:
		# 신규 무기 생성 및 장착
		var scene = load(wdata["scene_path"]) as PackedScene
		if scene:
			var weapon_instance = scene.instantiate()
			player.add_child(weapon_instance)
			equipped_weapons[wid] = {
				"level": 1,
				"node": weapon_instance,
				"is_evolved": false
			}
			# 현재 패시브 보정치 반영
			_apply_passives_to_weapon(weapon_instance)

func _upgrade_passive(pid: String) -> void:
	if equipped_passives.has(pid):
		equipped_passives[pid]["level"] += 1
	else:
		equipped_passives[pid] = {"level": 1}
		
	_recalculate_passive_modifiers()

func _recalculate_passive_modifiers() -> void:
	might_multiplier = 1.0
	cooldown_multiplier = 1.0
	speed_multiplier = 1.0
	pickup_radius_multiplier = 1.0
	
	if equipped_passives.has("passive_might"):
		might_multiplier += 0.1 * equipped_passives["passive_might"]["level"]
	if equipped_passives.has("passive_empty_tome"):
		cooldown_multiplier = max(0.5, 1.0 - (0.08 * equipped_passives["passive_empty_tome"]["level"]))
	if equipped_passives.has("passive_swift_boots"):
		speed_multiplier += 0.12 * equipped_passives["passive_swift_boots"]["level"]
	if equipped_passives.has("passive_attractorb"):
		pickup_radius_multiplier += 0.3 * equipped_passives["passive_attractorb"]["level"]
	if equipped_passives.has("passive_vitality") and player:
		player.max_hp = 100.0 + (20.0 * equipped_passives["passive_vitality"]["level"])
		player.heal(30.0)
		
	# 플레이어 본체 스탯 갱신
	if player:
		player.speed = 220.0 * speed_multiplier
		player._update_pickup_radius(240.0 * pickup_radius_multiplier)
		
	# 모든 무기 노드에 보정치 전파
	for wid in equipped_weapons:
		var node = equipped_weapons[wid]["node"]
		if node:
			_apply_passives_to_weapon(node)

func _apply_passives_to_weapon(weapon_node: Node2D) -> void:
	if "might_multiplier" in weapon_node:
		weapon_node.might_multiplier = might_multiplier
	if "cooldown_multiplier" in weapon_node:
		weapon_node.cooldown_multiplier = cooldown_multiplier

# 진화 가능한 무기 탐색 (8레벨 무기 + 대응 패시브 보유 시)
func get_eligible_evolution() -> Dictionary:
	for wid in equipped_weapons:
		var item = equipped_weapons[wid]
		if item["level"] >= 8 and not item["is_evolved"]:
			var wdata = weapon_db[wid]
			var req_passive = wdata["required_passive"]
			if equipped_passives.has(req_passive):
				var evo_id = wdata["evolves_to"]
				var evo_data = evolution_db[evo_id]
				return {
					"base_weapon_id": wid,
					"evolution_id": evo_id,
					"title": evo_data["title"],
					"description": evo_data["description"]
				}
	return {}

# 무기 진화 수행
func evolve_weapon(base_weapon_id: String) -> void:
	if not equipped_weapons.has(base_weapon_id):
		return
	var item = equipped_weapons[base_weapon_id]
	item["is_evolved"] = true
	var node = item["node"]
	if node and node.has_method("evolve"):
		node.evolve()
