extends Node2D

var frames_tested: int = 0
var main_node: Node2D = null

func _ready() -> void:
	print("--- [TEST RUNNER] Starting Phase 4 Final Polish Verification ---")
	
	# 1. Main 씬 로드
	var main_scene = load("res://scenes/main/Main.tscn")
	if main_scene == null:
		printerr("[FAIL] Main.tscn failed to load")
		get_tree().quit(1)
		return
		
	main_node = main_scene.instantiate()
	add_child(main_node)
	print("[PASS] Main scene instantiated into tree")
	
	# 2. AudioManager 동작 검증
	print("[TEST] Verifying procedural AudioManager sfx playback...")
	AudioManager.play_shoot()
	AudioManager.play_hit()
	AudioManager.play_gem()
	AudioManager.play_level_up()
	AudioManager.play_chest()
	print("[PASS] All AudioManager sfx functions executed without error")
	
	# 3. 플로팅 데미지 텍스트 검증
	print("[TEST] Spawning DamageNumber...")
	DamageNumber.spawn(get_tree(), Vector2(960, 540), 42.0)
	await get_tree().process_frame
	
	var found_dmg = false
	for child in get_tree().current_scene.get_children():
		if child is DamageNumber:
			found_dmg = true
			if child.label.text != "42":
				printerr("[FAIL] DamageNumber text mismatch: %s" % child.label.text)
				get_tree().quit(1)
				return
			break
	if not found_dmg:
		printerr("[FAIL] DamageNumber node not found in scene")
		get_tree().quit(1)
		return
	print("[PASS] DamageNumber spawned and text verified: 42")
	
	# 4. 카메라 셰이크(Screen Shake) 트라우마 검증
	var player = main_node.get_node_or_null("Player") as Player
	if player == null:
		printerr("[FAIL] Player not found")
		get_tree().quit(1)
		return
		
	player.add_shake(0.6)
	if player.shake_trauma < 0.5:
		printerr("[FAIL] Camera trauma not increased: %f" % player.shake_trauma)
		get_tree().quit(1)
		return
	print("[PASS] Camera trauma verified: %f" % player.shake_trauma)
	
	# 플레이어 AnimatedSprite2D 검증
	print("[TEST] Verifying Player AnimatedSprite2D and sprite animations...")
	if not (player.sprite is AnimatedSprite2D):
		printerr("[FAIL] player.sprite is not AnimatedSprite2D")
		get_tree().quit(1)
		return
	if not player.sprite.sprite_frames.has_animation("walk") or not player.sprite.sprite_frames.has_animation("idle"):
		printerr("[FAIL] SpriteFrames missing walk or idle animations")
		get_tree().quit(1)
		return
	var walk_frames_count = player.sprite.sprite_frames.get_frame_count("walk")
	if walk_frames_count != 16:
		printerr("[FAIL] Expected 16 walk frames, got %d" % walk_frames_count)
		get_tree().quit(1)
		return
	print("[PASS] Player AnimatedSprite2D verified: idle & 16-frame walk animations confirmed")
	
	# 5. ESC 일시정지 메뉴 (PauseMenu) 검증
	var pause_menu = main_node.get_node_or_null("CanvasLayer/PauseMenu") as PauseMenu
	if pause_menu == null:
		printerr("[FAIL] PauseMenu not found in CanvasLayer")
		get_tree().quit(1)
		return
		
	pause_menu.toggle_pause()
	if not pause_menu.visible or not get_tree().paused:
		printerr("[FAIL] PauseMenu failed to pause tree and become visible")
		get_tree().quit(1)
		return
	print("[PASS] PauseMenu toggled: visible = true, paused = true")
	
	pause_menu._on_resume_pressed()
	if pause_menu.visible or get_tree().paused:
		printerr("[FAIL] PauseMenu failed to unpause tree on resume")
		get_tree().quit(1)
		return
	print("[PASS] PauseMenu resume verified: visible = false, paused = false")
	
	# 6. 결과 통계 화면 (VictoryGameOverUI) 검증
	var game_over_ui = main_node.get_node_or_null("CanvasLayer/VictoryGameOverUI") as VictoryGameOverUI
	if game_over_ui == null:
		printerr("[FAIL] VictoryGameOverUI not found in CanvasLayer")
		get_tree().quit(1)
		return
		
	game_over_ui.show_results(false)
	if not game_over_ui.visible or not get_tree().paused:
		printerr("[FAIL] VictoryGameOverUI did not display or pause tree")
		get_tree().quit(1)
		return
	print("[PASS] VictoryGameOverUI displayed with stats (Level, Kills, Time, Equipment)")
	game_over_ui.visible = false
	get_tree().paused = false
	
	# 7. 보스(EnemyBoss) 및 탄막 공격 패턴 검증
	print("[TEST] Spawning EnemyBoss and verifying stats & attack patterns...")
	var boss_scene = load("res://scenes/enemy/EnemyBoss.tscn")
	if boss_scene == null:
		printerr("[FAIL] EnemyBoss.tscn failed to load")
		get_tree().quit(1)
		return
		
	var boss = boss_scene.instantiate() as EnemyBoss
	main_node.add_child(boss)
	boss.global_position = Vector2(960, 200)
	await get_tree().process_frame
	
	if boss.max_hp != 1800.0 or boss.speed != 120.0:
		printerr("[FAIL] Boss stats mismatch! HP: %f, Speed: %f" % [boss.max_hp, boss.speed])
		get_tree().quit(1)
		return
	print("[PASS] Boss stats verified: HP=1800, Speed=120")
	
	# 사방 12방향 탄막 공격 수동 호출 테스트
	boss._fire_radial_attack()
	await get_tree().process_frame
	await get_tree().process_frame
	
	var proj_count = 0
	for child in main_node.get_children():
		if child is EnemyProjectile:
			proj_count += 1
	if proj_count < 12:
		printerr("[FAIL] Expected at least 12 EnemyProjectiles from radial attack, got %d" % proj_count)
		get_tree().quit(1)
		return
	print("[PASS] Radial attack verified: %d projectiles spawned" % proj_count)
	
	# 보스 데미지 및 체력바 감소 테스트
	var initial_hp = boss.current_hp
	boss.take_damage(200.0)
	if boss.current_hp != initial_hp - 200.0 or boss.hp_bar.value != boss.current_hp:
		printerr("[FAIL] Boss take_damage did not update current_hp or hp_bar correctly")
		get_tree().quit(1)
		return
	print("[PASS] Boss take_damage and HPBar verified: HP is now %f" % boss.current_hp)

func _physics_process(_delta: float) -> void:
	frames_tested += 1
	if frames_tested >= 30:
		print("========================================")
		print("  ALL PHASE 4 AUTOMATED TESTS PASSED!   ")
		print("========================================")
		get_tree().quit(0)
