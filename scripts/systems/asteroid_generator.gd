extends Node
class_name AsteroidGenerator

## Procedural asteroid field generation system
##
## Generates non-overlapping asteroids with random stats using rejection sampling.
## Can be upgraded to Poisson disk sampling for better distribution.

const ASTEROID_SCENE = preload("res://scenes/asteroids/asteroid.tscn")

# Generation parameters
const MIN_RADIUS = 30.0
const MAX_RADIUS = 80.0
const MIN_SPACING = 20.0  # Minimum gap between asteroids

const MIN_ENERGY = 50.0
const MAX_ENERGY = 150.0

const MIN_DEFENSE = 0.8
const MAX_DEFENSE = 1.5

const MIN_SPEED = 0.8
const MAX_SPEED = 1.5


## Generate asteroids in a given play area using rejection sampling
static func generate_asteroids(count: int, play_area: Rect2) -> Array[Asteroid]:
	var asteroids: Array[Asteroid] = []
	var attempts = 0
	var max_attempts = count * 10  # Prevent infinite loops

	while asteroids.size() < count and attempts < max_attempts:
		var pos = _random_position_in_rect(play_area)
		var rad = randf_range(MIN_RADIUS, MAX_RADIUS)

		# Check for overlaps with existing asteroids
		if not _overlaps_existing(pos, rad, asteroids):
			var asteroid = _create_asteroid(pos, rad)
			asteroids.append(asteroid)

		attempts += 1

	if asteroids.size() < count:
		push_warning("AsteroidGenerator: Could only place %d/%d asteroids" % [asteroids.size(), count])

	return asteroids


## Generate asteroids with Poisson disk sampling (better distribution)
## This creates a more natural, evenly-spaced appearance
static func generate_asteroids_poisson(count: int, play_area: Rect2, min_distance: float = 150.0) -> Array[Asteroid]:
	var points = _poisson_disk_sampling(play_area, min_distance, 30)

	# Limit to requested count
	if points.size() > count:
		points.resize(count)

	var asteroids: Array[Asteroid] = []
	for point in points:
		var rad = randf_range(MIN_RADIUS, MAX_RADIUS)
		var asteroid = _create_asteroid(point, rad)
		asteroids.append(asteroid)

	return asteroids


## Create a single asteroid with random stats
static func _create_asteroid(pos: Vector2, rad: float) -> Asteroid:
	var asteroid = ASTEROID_SCENE.instantiate() as Asteroid

	# Set position and radius
	asteroid.position = pos
	asteroid.radius = rad

	# Randomize stats
	asteroid.max_energy = randf_range(MIN_ENERGY, MAX_ENERGY)
	asteroid.defense_bonus = randf_range(MIN_DEFENSE, MAX_DEFENSE)
	asteroid.speed_bonus = randf_range(MIN_SPEED, MAX_SPEED)

	# Start neutral
	asteroid.owner_id = -1
	asteroid.current_spores = 0

	return asteroid


## Check if a position overlaps with existing asteroids
static func _overlaps_existing(pos: Vector2, rad: float, asteroids: Array[Asteroid]) -> bool:
	for existing in asteroids:
		var distance = pos.distance_to(existing.position)
		var min_distance = rad + existing.radius + MIN_SPACING

		if distance < min_distance:
			return true

	return false


## Get random position within rectangle
static func _random_position_in_rect(rect: Rect2) -> Vector2:
	var x = randf_range(rect.position.x, rect.position.x + rect.size.x)
	var y = randf_range(rect.position.y, rect.position.y + rect.size.y)
	return Vector2(x, y)


## Poisson disk sampling for evenly distributed points
## Based on Bridson's algorithm
static func _poisson_disk_sampling(area: Rect2, min_distance: float, max_attempts: int = 30) -> Array[Vector2]:
	var points: Array[Vector2] = []
	var active_list: Array[Vector2] = []

	# Start with a random point
	var initial = _random_position_in_rect(area)
	points.append(initial)
	active_list.append(initial)

	while active_list.size() > 0:
		# Pick a random active point
		var idx = randi() % active_list.size()
		var point = active_list[idx]
		var found = false

		# Try to generate new points around it
		for i in max_attempts:
			var angle = randf() * TAU
			var distance = randf_range(min_distance, min_distance * 2)
			var new_point = point + Vector2.RIGHT.rotated(angle) * distance

			if _is_valid_poisson_point(new_point, points, area, min_distance):
				points.append(new_point)
				active_list.append(new_point)
				found = true
				break

		# If no valid point found, remove from active list
		if not found:
			active_list.remove_at(idx)

	return points


## Check if a point is valid for Poisson disk sampling
static func _is_valid_poisson_point(point: Vector2, existing_points: Array[Vector2], area: Rect2, min_distance: float) -> bool:
	# Check if within bounds
	if not area.has_point(point):
		return false

	# Check distance to all existing points
	for existing in existing_points:
		if point.distance_to(existing) < min_distance:
			return false

	return true


## Assign starting asteroids to players
## Returns dictionary: { "player": Asteroid, "ai": Asteroid }
static func assign_starting_asteroids(asteroids: Array[Asteroid]) -> Dictionary:
	if asteroids.size() < 2:
		push_error("AsteroidGenerator: Need at least 2 asteroids for starting positions")
		return {}

	# Find two asteroids far apart for starting positions
	var max_distance = 0.0
	var player_asteroid: Asteroid = null
	var ai_asteroid: Asteroid = null

	for i in asteroids.size():
		for j in range(i + 1, asteroids.size()):
			var distance = asteroids[i].position.distance_to(asteroids[j].position)
			if distance > max_distance:
				max_distance = distance
				player_asteroid = asteroids[i]
				ai_asteroid = asteroids[j]

	# Assign ownership and starting spores
	if player_asteroid:
		player_asteroid.owner_id = 0
		player_asteroid.current_spores = 50

	if ai_asteroid:
		ai_asteroid.owner_id = 1
		ai_asteroid.current_spores = 50

	return {
		"player": player_asteroid,
		"ai": ai_asteroid
	}
