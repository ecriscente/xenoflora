extends GdUnitTestSuite

## Unit tests for AsteroidGenerator
##
## Tests procedural generation, overlap checking, and starting position assignment

const AsteroidGenerator = preload("res://scripts/systems/asteroid_generator.gd")

var test_play_area: Rect2


func before_test():
	# Standard play area for tests
	test_play_area = Rect2(-800, -400, 1600, 800)


func after_test():
	# Cleanup any generated asteroids
	pass


## Test that correct number of asteroids are generated
func test_generates_correct_count():
	var asteroids = AsteroidGenerator.generate_asteroids(15, test_play_area)

	assert_int(asteroids.size()).is_equal(15)


## Test that generated asteroids are within play area
func test_asteroids_within_play_area():
	var asteroids = AsteroidGenerator.generate_asteroids(10, test_play_area)

	for asteroid in asteroids:
		# Check position is within bounds (accounting for radius)
		var expanded_area = test_play_area.grow(asteroid.radius)
		assert_bool(expanded_area.has_point(asteroid.position)).is_true()


## Test that no asteroids overlap
func test_no_overlapping_asteroids():
	var asteroids = AsteroidGenerator.generate_asteroids(15, test_play_area)

	for i in asteroids.size():
		for j in range(i + 1, asteroids.size()):
			var asteroid_a = asteroids[i]
			var asteroid_b = asteroids[j]
			var distance = asteroid_a.position.distance_to(asteroid_b.position)
			var min_distance = asteroid_a.radius + asteroid_b.radius + AsteroidGenerator.MIN_SPACING

			assert_float(distance).is_greater_equal(min_distance)


## Test that asteroid properties are within expected ranges
func test_asteroid_properties_in_range():
	var asteroids = AsteroidGenerator.generate_asteroids(10, test_play_area)

	for asteroid in asteroids:
		# Check radius
		assert_float(asteroid.radius).is_between(AsteroidGenerator.MIN_RADIUS, AsteroidGenerator.MAX_RADIUS)

		# Check energy
		assert_float(asteroid.max_energy).is_between(AsteroidGenerator.MIN_ENERGY, AsteroidGenerator.MAX_ENERGY)

		# Check defense
		assert_float(asteroid.defense_bonus).is_between(AsteroidGenerator.MIN_DEFENSE, AsteroidGenerator.MAX_DEFENSE)

		# Check speed
		assert_float(asteroid.speed_bonus).is_between(AsteroidGenerator.MIN_SPEED, AsteroidGenerator.MAX_SPEED)


## Test that all generated asteroids start neutral
func test_asteroids_start_neutral():
	var asteroids = AsteroidGenerator.generate_asteroids(10, test_play_area)

	for asteroid in asteroids:
		assert_int(asteroid.owner_id).is_equal(-1)
		assert_int(asteroid.current_spores).is_equal(0)


## Test starting asteroid assignment
func test_assign_starting_asteroids():
	var asteroids = AsteroidGenerator.generate_asteroids(15, test_play_area)
	var starting = AsteroidGenerator.assign_starting_asteroids(asteroids)

	# Should return player and AI asteroids
	assert_object(starting).is_not_null()
	assert_bool(starting.has("player")).is_true()
	assert_bool(starting.has("ai")).is_true()

	var player_asteroid = starting["player"]
	var ai_asteroid = starting["ai"]

	# Check ownership
	assert_int(player_asteroid.owner_id).is_equal(0)
	assert_int(ai_asteroid.owner_id).is_equal(1)

	# Check starting spores
	assert_int(player_asteroid.current_spores).is_equal(50)
	assert_int(ai_asteroid.current_spores).is_equal(50)

	# Check they are different asteroids
	assert_object(player_asteroid).is_not_same(ai_asteroid)


## Test that starting asteroids are far apart
func test_starting_asteroids_are_distant():
	var asteroids = AsteroidGenerator.generate_asteroids(15, test_play_area)
	var starting = AsteroidGenerator.assign_starting_asteroids(asteroids)

	var player_asteroid = starting["player"]
	var ai_asteroid = starting["ai"]

	# Should be the maximum distance apart
	var distance = player_asteroid.position.distance_to(ai_asteroid.position)

	# Find max possible distance in the array
	var max_distance = 0.0
	for i in asteroids.size():
		for j in range(i + 1, asteroids.size()):
			var d = asteroids[i].position.distance_to(asteroids[j].position)
			if d > max_distance:
				max_distance = d

	# Starting asteroids should have maximum distance
	assert_float(distance).is_equal(max_distance)


## Test Poisson disk sampling generates non-overlapping points
func test_poisson_disk_sampling():
	var asteroids = AsteroidGenerator.generate_asteroids_poisson(15, test_play_area, 150.0)

	# Should generate asteroids
	assert_int(asteroids.size()).is_greater(0)
	assert_int(asteroids.size()).is_less_equal(15)

	# Check no overlaps (with more strict spacing from Poisson)
	for i in asteroids.size():
		for j in range(i + 1, asteroids.size()):
			var distance = asteroids[i].position.distance_to(asteroids[j].position)
			# Minimum distance should be enforced (150.0 - radii, but check against MIN_SPACING)
			var min_distance = asteroids[i].radius + asteroids[j].radius + AsteroidGenerator.MIN_SPACING
			assert_float(distance).is_greater_equal(min_distance)


## Test with insufficient space (should warn and return fewer asteroids)
func test_generation_with_insufficient_space():
	var small_area = Rect2(0, 0, 100, 100)
	var asteroids = AsteroidGenerator.generate_asteroids(50, small_area)

	# Should generate fewer than requested
	assert_int(asteroids.size()).is_less(50)


## Test edge case: requesting 0 asteroids
func test_generate_zero_asteroids():
	var asteroids = AsteroidGenerator.generate_asteroids(0, test_play_area)

	assert_int(asteroids.size()).is_equal(0)


## Test edge case: very large play area
func test_generate_in_large_area():
	var large_area = Rect2(-5000, -5000, 10000, 10000)
	var asteroids = AsteroidGenerator.generate_asteroids(20, large_area)

	assert_int(asteroids.size()).is_equal(20)

	# All should be within bounds
	for asteroid in asteroids:
		var expanded_area = large_area.grow(asteroid.radius)
		assert_bool(expanded_area.has_point(asteroid.position)).is_true()
