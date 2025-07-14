extends Camera2D

@export_category("Target & Follow Settings")
@export var target_path: NodePath
@export var follow_speed: float = 5.0
@export var vertical_offset: float = 0.0
@export var enable_look_ahead: bool = true
@export var look_ahead_distance: float = 64.0
@export var look_ahead_smoothness: float = 5.0

@export_category("Zoom Settings")
@export var zoom_amount: Vector2 = Vector2(1, 1)
@export var zoom_speed: float = 2.0

@export_category("Boundary Settings")
@export var extra_margin: Vector2 = Vector2(0, 0)

var _target: Node2D
var _look_ahead_offset: Vector2 = Vector2.ZERO
var _target_last_position: Vector2 = Vector2.ZERO
var _level_bounds: Rect2 = Rect2()


func _ready():
	_target = get_node_or_null(target_path)
	if not _target:
		push_error("Camera target not found!")
		return

	_target_last_position = _target.global_position
	position = _target.global_position

	# Apply default zoom
	zoom = zoom_amount

	# Calculate boundaries if a tilemap is assigned
	var bounds_node = get_tree().get_current_scene()
	if bounds_node:
		_level_bounds = _compute_bounds_from_tilemap_layers(bounds_node)
		print("Computed level bound:", _level_bounds)
		limit_left   = int(_level_bounds.position.x)
		limit_top    = int(_level_bounds.position.y)
		limit_right  = int(_level_bounds.position.x + _level_bounds.size.x)
		limit_bottom = int(_level_bounds.position.y + _level_bounds.size.y)
	else:
		push_warning("Boundary node not found.")

func _process(delta):
	if not _target:
		return

	# Calculate look ahead offset
	if enable_look_ahead:
		var move_delta = _target.global_position - _target_last_position
		var look_direction = move_delta.normalized()
		var desired_look = look_direction * look_ahead_distance
		_look_ahead_offset = _look_ahead_offset.lerp(desired_look, delta * look_ahead_smoothness)
	else:
		_look_ahead_offset = Vector2.ZERO


	var desired_position = _target.global_position + Vector2(0, vertical_offset) + _look_ahead_offset
	var smoothed_position = global_position.lerp(desired_position, delta * follow_speed)

	global_position = smoothed_position

	# Smooth zoom (optional)
	zoom = zoom.lerp(zoom_amount, delta * zoom_speed)
	_target_last_position = _target.global_position
	

	
func _compute_bounds_from_tilemap_layers(root_node: Node) -> Rect2i:
	var rect = null
	for tilemap in get_all_nodes_of_type(root_node, "TileMapLayer"):
		if tilemap is TileMapLayer:
			var used = tilemap.get_used_rect()
			print("For tilemap:", tilemap)
			print("used tilemap rect: ", used)
			var cell_size = tilemap.tile_set.tile_size
			var local_rect = Rect2i(
				used.position * cell_size,
				used.size * cell_size
			)
			print("used local rect: ", local_rect)
			var global_rect = Rect2i(tilemap.to_global(local_rect.position), local_rect.size)
			print("Global rect", global_rect)
			if rect: 
				rect = rect.merge(global_rect)
			else:
				rect = global_rect
			
	print("Calculated rect:", rect)
	return rect.grow_individual(extra_margin.x, extra_margin.y, extra_margin.x, extra_margin.y)

	
func get_all_nodes_of_type(root: Node, type_class: String) -> Array:
	var results = []
	if root is Node:
		for child in root.get_children():
			if child is Node:
				if child.is_class(type_class):
					results.append(child)
				results += get_all_nodes_of_type(child, type_class)
	return results
