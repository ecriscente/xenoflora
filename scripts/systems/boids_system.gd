extends Node

## Boids System - Spatial grid for efficient neighbor queries
##
## Phase 1.1: Skeleton implementation
## Provides registration/unregistration for spore units
## Will implement spatial grid and force calculations incrementally

# Grid configuration
const CELL_SIZE: int = 100
const PERCEPTION_RADIUS: float = 50.0

# Update configuration
const UPDATE_GROUPS: int = 3
var update_frame: int = 0

# Spatial grid: Dictionary[Vector2i, Array[SporeUnit]]
var spatial_grid: Dictionary = {}

# All units (for staggered updates)
var all_units: Array = []

# Performance tracking
var boids_time_ms: float = 0.0


func _ready() -> void:
	pass  # BoidsSystem ready


func _process(delta: float) -> void:
	# Performance tracking
	var start = Time.get_ticks_usec()

	# Update spatial grid (move units between cells)
	_update_spatial_grid()

	# Update boids with staggered processing
	_update_boids_staggered(delta)

	# Track performance
	boids_time_ms = (Time.get_ticks_usec() - start) / 1000.0


## Register a spore unit with the boids system
func register_unit(unit) -> void:
	# Add to tracking array
	all_units.append(unit)

	# Add to spatial grid
	var cell = world_to_cell(unit.position)
	if not spatial_grid.has(cell):
		spatial_grid[cell] = []
	spatial_grid[cell].append(unit)

	# Store cell on unit for efficient updates
	unit.set_meta("grid_cell", cell)


## Unregister a spore unit from the boids system
func unregister_unit(unit) -> void:
	# Remove from tracking array
	all_units.erase(unit)

	# Remove from spatial grid
	if unit.has_meta("grid_cell"):
		var cell = unit.get_meta("grid_cell")
		if spatial_grid.has(cell):
			spatial_grid[cell].erase(unit)
			# Clean up empty cells
			if spatial_grid[cell].size() == 0:
				spatial_grid.erase(cell)


## Update spatial grid - move units between cells as they travel
func _update_spatial_grid() -> void:
	for unit in all_units:
		if not is_instance_valid(unit):
			continue

		var current_cell = unit.get_meta("grid_cell") if unit.has_meta("grid_cell") else null
		var new_cell = world_to_cell(unit.position)

		# Only update if cell changed
		if current_cell != new_cell:
			# Remove from old cell
			if current_cell and spatial_grid.has(current_cell):
				spatial_grid[current_cell].erase(unit)
				if spatial_grid[current_cell].size() == 0:
					spatial_grid.erase(current_cell)

			# Add to new cell
			if not spatial_grid.has(new_cell):
				spatial_grid[new_cell] = []
			spatial_grid[new_cell].append(unit)
			unit.set_meta("grid_cell", new_cell)


## Update boids behavior with staggered processing (1/3 of units per frame)
func _update_boids_staggered(delta: float) -> void:
	if all_units.size() == 0:
		return

	var units_per_group = ceili(float(all_units.size()) / UPDATE_GROUPS)
	var start_idx = update_frame * units_per_group
	var end_idx = min(start_idx + units_per_group, all_units.size())

	for i in range(start_idx, end_idx):
		if i >= all_units.size():
			break

		var unit = all_units[i]
		if not is_instance_valid(unit) or unit.has_arrived:
			continue

		var neighbors = get_neighbors(unit)
		unit.apply_boids(neighbors, delta * UPDATE_GROUPS)  # Scale delta!

	update_frame = (update_frame + 1) % UPDATE_GROUPS


## Get neighbors within perception radius
func get_neighbors(unit) -> Array:
	var neighbors: Array = []
	var cell = world_to_cell(unit.position)

	# Check 3x3 grid of cells (current + 8 surrounding)
	for dx in [-1, 0, 1]:
		for dy in [-1, 0, 1]:
			var check_cell = cell + Vector2i(dx, dy)
			if spatial_grid.has(check_cell):
				for other in spatial_grid[check_cell]:
					# Skip self
					if other == unit:
						continue

					var distance = unit.position.distance_to(other.position)
					if distance <= PERCEPTION_RADIUS:
						neighbors.append(other)

	return neighbors


## Convert world position to grid cell coordinates
func world_to_cell(world_pos: Vector2) -> Vector2i:
	return Vector2i(
		int(floor(world_pos.x / CELL_SIZE)),
		int(floor(world_pos.y / CELL_SIZE))
	)
