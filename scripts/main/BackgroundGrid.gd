extends Node2D

@export var grid_size: float = 64.0
@export var grid_color: Color = Color(0.18, 0.20, 0.26, 1.0)
@export var bg_color: Color = Color(0.09, 0.10, 0.13, 1.0)

var camera: Camera2D

func _ready() -> void:
	z_index = -10

func _process(_delta: float) -> void:
	if not is_instance_valid(camera):
		camera = get_viewport().get_camera_2d()
	queue_redraw()

func _draw() -> void:
	var cam_pos = camera.global_position if is_instance_valid(camera) else Vector2.ZERO
	var vp_size = get_viewport_rect().size * 1.5
	
	# 월드 배경 사각형
	draw_rect(Rect2(cam_pos - vp_size, vp_size * 2.0), bg_color)
	
	# 카메라 이동에 연동되는 절차적 그리드 라인
	var start_x = floor((cam_pos.x - vp_size.x) / grid_size) * grid_size
	var end_x = ceil((cam_pos.x + vp_size.x) / grid_size) * grid_size
	var start_y = floor((cam_pos.y - vp_size.y) / grid_size) * grid_size
	var end_y = ceil((cam_pos.y + vp_size.y) / grid_size) * grid_size
	
	var x = start_x
	while x <= end_x:
		draw_line(Vector2(x, start_y), Vector2(x, end_y), grid_color, 1.0)
		x += grid_size
		
	var y = start_y
	while y <= end_y:
		draw_line(Vector2(start_x, y), Vector2(end_x, y), grid_color, 1.0)
		y += grid_size
