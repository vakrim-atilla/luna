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
@export var detect_bounds_from_tilemap: bool = true
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
	if detect_bounds_from_tilemap:
		var bounds_node = get_tree().get_current_scene()

		if bounds_node:
			_level_bounds = _compute_bounds_from_tilemap_layers(bounds_node)
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

	# Calculate desired camera position
	var desired_position = _target.global_position + Vector2(0, vertical_offset) + _look_ahead_offset
	global_position = global_position.lerp(desired_position, delta * follow_speed)

	# Clamp to level bounds if defined
	if _level_bounds.size != Vector2.ZERO:
		var half_screen = get_viewport_rect().size * 0.5 * zoom
		var clamped_pos = global_position.clamp(
			_level_bounds.position + half_screen,
			_level_bounds.position + _level_bounds.size - half_screen
		)
		global_position = clamped_pos

	# Smooth zoom (optional)
	zoom = zoom.lerp(zoom_amount, delta * zoom_speed)

	_target_last_position = _target.global_position

func _compute_bounds_from_tilemap_layers(root_node: Node) -> Rect2:
	var min_pos = Vector2.INF
	var max_pos = -Vector2.INF

	for tilemap in get_all_nodes_of_type(root_node, "TileMapLayer"):
		if tilemap is TileMap:
			var tile_set = tilemap.tile_set
			var layer_count = tilemap.get_layers_count()

			for layer in range(layer_count):
				for cell in tilemap.get_used_cells(layer):
					var source_id = tilemap.get_cell_source_id(layer, cell)
					var atlas_coords = tilemap.get_cell_atlas_coords(layer, cell)

					if source_id == -1 or not tile_set.has_source(source_id):
						continue

					var source = tile_set.get_source(source_id)
					if not source:
						continue

					var tile_data = source.get_tile_data(atlas_coords)
					if tile_data == null:
						continue

					var collision_shapes = tile_data.get_collision_shapes()
					for shape_data in collision_shapes:
						var shape_pos = tilemap.map_to_local(cell) + shape_data.transform.origin
						var shape = shape_data.shape

						if shape is RectangleShape2D:
							var extents = shape.extents
							var aabb = Rect2(shape_pos - extents, extents * 2)
							min_pos = min_pos.min(aabb.position)
							max_pos = max_pos.max(aabb.position + aabb.size)

						elif shape is CapsuleShape2D or shape is CircleShape2D:
							var radius = shape.radius
							var aabb = Rect2(shape_pos - Vector2(radius, radius), Vector2(radius * 2, radius * 2))
							min_pos = min_pos.min(aabb.position)
							max_pos = max_pos.max(aabb.position + aabb.size)

						elif shape is ConvexPolygonShape2D:
							for point in shape.points:
								var world_point = shape_pos + point
								min_pos = min_pos.min(world_point)
								max_pos = max_pos.max(world_point)

	var boundary = Rect2(min_pos, max_pos - min_pos)
	return boundary.grow_individual(extra_margin.x, extra_margin.y, extra_margin.x, extra_margin.y)
	
func get_all_nodes_of_type(root: Node, type_class: String) -> Array:
	var results = []
	if root is Node:
		for child in root.get_children():
			if child is Node:
				if child.is_class(type_class):
					results.append(child)
				results += get_all_nodes_of_type(child, type_class)
	return results
