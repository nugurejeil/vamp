extends Node

## 프로시저럴 레트로 사운드 매니저 (Autoload)
## 외부 음원 파일 없이 GDScript 코드로 즉석에서 8-bit 아케이드 사운드를 합성하여 재생합니다.

const MIX_RATE = 22050

var _players: Array[AudioStreamPlayer] = []
var _sfx_cache: Dictionary = {}
var _current_player_idx: int = 0
var _last_hit_time: float = -1.0
const MIN_HIT_INTERVAL: float = 0.04 # 다수 적 동시 피격 시 오디오 왜곡/클리핑 방지

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	# 폴리포닉 사운드 플레이어 풀 생성 (동시 재생 채널 16개로 확장)
	for i in range(16):
		var p = AudioStreamPlayer.new()
		add_child(p)
		_players.append(p)
		
	# 1. 플레이어 공격 효과음: attack_player.mp3 우선 로드 (fallback: 프로시저럴 레이저)
	if ResourceLoader.exists("res://attack_player.mp3"):
		_sfx_cache["shoot"] = load("res://attack_player.mp3")
	else:
		_sfx_cache["shoot"] = _generate_laser()
		
	# 2. 적 피격 효과음: die_enemy.mp3 우선 로드 (fallback: 프로시저럴 피격음)
	if ResourceLoader.exists("res://die_enemy.mp3"):
		_sfx_cache["hit"] = load("res://die_enemy.mp3")
	else:
		_sfx_cache["hit"] = _generate_hit()
		
	# 기타 사운드 프리셋 합성
	_sfx_cache["gem"] = _generate_gem()
	_sfx_cache["level_up"] = _generate_level_up()
	_sfx_cache["chest"] = _generate_fanfare()
	_sfx_cache["game_over"] = _generate_game_over()
	
	# 전역 이벤트 연결
	EventBus.level_up.connect(func(_l): play_level_up())
	EventBus.chest_opened.connect(func(): play_chest())
	EventBus.player_died.connect(func(): play_game_over())

func play_shoot() -> void:
	_play_stream(_sfx_cache.get("shoot"), 0.0, randf_range(0.96, 1.04))

func play_attack() -> void:
	play_shoot()

func play_hit() -> void:
	var now = Time.get_ticks_msec() / 1000.0
	if now - _last_hit_time < MIN_HIT_INTERVAL:
		return
	_last_hit_time = now
	_play_stream(_sfx_cache.get("hit"), 0.0, randf_range(0.95, 1.05))

func play_gem() -> void:
	_play_stream(_sfx_cache.get("gem"))

func play_level_up() -> void:
	_play_stream(_sfx_cache.get("level_up"))

func play_chest() -> void:
	_play_stream(_sfx_cache.get("chest"))

func play_game_over() -> void:
	_play_stream(_sfx_cache.get("game_over"))

func _play_stream(stream: AudioStream, volume_db: float = 0.0, pitch: float = 1.0) -> void:
	if stream == null:
		return
	for p in _players:
		if not p.playing:
			p.stream = stream
			p.volume_db = volume_db
			p.pitch_scale = pitch
			p.play()
			return
	# 모두 재생 중이면 라운드 로빈 방식으로 채널 순환 재사용
	var p = _players[_current_player_idx]
	_current_player_idx = (_current_player_idx + 1) % _players.size()
	p.stream = stream
	p.volume_db = volume_db
	p.pitch_scale = pitch
	p.play()

# 1. 레이저 발사음 (주파수 하강 톱니/사각파)
func _generate_laser() -> AudioStreamWAV:
	var duration = 0.12
	var samples = int(MIX_RATE * duration)
	var data = PackedByteArray()
	data.resize(samples)
	var phase = 0.0
	for i in range(samples):
		var t = float(i) / samples
		var freq = lerp(880.0, 220.0, t)
		phase += freq / MIX_RATE
		var val = 1.0 if fmod(phase, 1.0) > 0.5 else -1.0
		var envelope = 1.0 - t
		var byte_val = int((val * envelope * 0.4 + 1.0) * 127.5)
		data[i] = clamp(byte_val, 0, 255)
	return _make_wav(data)

# 2. 피격 둔탁음 (노이즈 + 저주파)
func _generate_hit() -> AudioStreamWAV:
	var duration = 0.09
	var samples = int(MIX_RATE * duration)
	var data = PackedByteArray()
	data.resize(samples)
	for i in range(samples):
		var t = float(i) / samples
		var noise = randf_range(-1.0, 1.0)
		var envelope = (1.0 - t) * (1.0 - t)
		var byte_val = int((noise * envelope * 0.45 + 1.0) * 127.5)
		data[i] = clamp(byte_val, 0, 255)
	return _make_wav(data)

# 3. 보석 수집음 (맑은 2화음 핑)
func _generate_gem() -> AudioStreamWAV:
	var duration = 0.14
	var samples = int(MIX_RATE * duration)
	var data = PackedByteArray()
	data.resize(samples)
	var phase1 = 0.0
	var phase2 = 0.0
	for i in range(samples):
		var t = float(i) / samples
		phase1 += 1320.0 / MIX_RATE
		phase2 += 1760.0 / MIX_RATE
		var val = (sin(phase1 * TAU) + sin(phase2 * TAU)) * 0.5
		var envelope = pow(1.0 - t, 1.8)
		var byte_val = int((val * envelope * 0.4 + 1.0) * 127.5)
		data[i] = clamp(byte_val, 0, 255)
	return _make_wav(data)

# 4. 레벨업 팡파레 (상승 4화음 아르페지오)
func _generate_level_up() -> AudioStreamWAV:
	var duration = 0.4
	var samples = int(MIX_RATE * duration)
	var data = PackedByteArray()
	data.resize(samples)
	var freqs = [523.25, 659.25, 783.99, 1046.50] # C5, E5, G5, C6
	var phase = 0.0
	for i in range(samples):
		var t = float(i) / samples
		var note_idx = int(t * 4.0)
		var freq = freqs[clamp(note_idx, 0, 3)]
		phase += freq / MIX_RATE
		var val = sin(phase * TAU)
		var envelope = 1.0 - fmod(t * 4.0, 1.0) * 0.5
		var byte_val = int((val * envelope * 0.45 + 1.0) * 127.5)
		data[i] = clamp(byte_val, 0, 255)
	return _make_wav(data)

# 5. 상자 오픈 팡파레
func _generate_fanfare() -> AudioStreamWAV:
	var duration = 0.55
	var samples = int(MIX_RATE * duration)
	var data = PackedByteArray()
	data.resize(samples)
	var freqs = [440.0, 554.37, 659.25, 880.0, 1108.73]
	var phase = 0.0
	for i in range(samples):
		var t = float(i) / samples
		var note_idx = int(t * 5.0)
		var freq = freqs[clamp(note_idx, 0, 4)]
		phase += freq / MIX_RATE
		var val = 1.0 if fmod(phase, 1.0) > 0.5 else -1.0
		var envelope = 1.0 - t * 0.8
		var byte_val = int((val * envelope * 0.35 + 1.0) * 127.5)
		data[i] = clamp(byte_val, 0, 255)
	return _make_wav(data)

# 6. 게임 오버음 (하강 음조)
func _generate_game_over() -> AudioStreamWAV:
	var duration = 0.6
	var samples = int(MIX_RATE * duration)
	var data = PackedByteArray()
	data.resize(samples)
	var phase = 0.0
	for i in range(samples):
		var t = float(i) / samples
		var freq = lerp(320.0, 80.0, t)
		phase += freq / MIX_RATE
		var val = sin(phase * TAU)
		var envelope = 1.0 - t
		var byte_val = int((val * envelope * 0.5 + 1.0) * 127.5)
		data[i] = clamp(byte_val, 0, 255)
	return _make_wav(data)

func _make_wav(data: PackedByteArray) -> AudioStreamWAV:
	var wav = AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_8_BITS
	wav.mix_rate = MIX_RATE
	wav.stereo = false
	wav.data = data
	return wav
