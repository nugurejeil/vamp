extends Node

## 고성능 오브젝트 풀링 (Object Pooling) 싱글톤
## 대량의 투사체 및 몬스터 생성/해제 시 발생하는 가비지 컬렉션을 최소화합니다.

var _pools: Dictionary = {}

func get_instance(scene: PackedScene) -> Node:
	if scene == null:
		return null
		
	var path = scene.resource_path
	if not _pools.has(path):
		_pools[path] = []
		
	var pool: Array = _pools[path]
	while pool.size() > 0:
		var candidate = pool.pop_back()
		if is_instance_valid(candidate) and not candidate.is_inside_tree():
			if candidate.has_method("reset_for_pool"):
				candidate.reset_for_pool()
			return candidate
			
	# 풀에 유효한 노드가 없으면 새로 인스턴스화
	return scene.instantiate()

func recycle_instance(node: Node, scene_path: String) -> void:
	if not is_instance_valid(node):
		return
		
	if not _pools.has(scene_path):
		_pools[scene_path] = []
		
	if node.is_inside_tree():
		node.get_parent().remove_child(node)
		
	_pools[scene_path].append(node)
