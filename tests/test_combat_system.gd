extends GdUnitTestSuite

## Unit tests for Combat System
##
## Tests combat resolution logic in GameManager.process_combat()

const ASTEROID_SCENE = preload("res://scenes/asteroids/asteroid.tscn")


func before_test():
	# Ensure GameManager is available (it's an autoload)
	assert_object(GameManager).is_not_null()


## Helper function to create a test asteroid
func create_test_asteroid(owner_id: int, spore_count: int, defense: float = 1.0) -> Asteroid:
	var asteroid = ASTEROID_SCENE.instantiate() as Asteroid
	asteroid.owner_id = owner_id
	asteroid.current_spores = spore_count
	asteroid.defense_bonus = defense
	asteroid.max_energy = 100.0
	return asteroid


## Test successful capture with overwhelming force
func test_successful_capture():
	var target = create_test_asteroid(-1, 10, 1.0)  # Neutral, 10 spores, 1.0 defense

	# Attack with 20 spores (enough to overcome 10 * 1.0 = 10 defense)
	GameManager.process_combat(20, 0, target)

	# Should be captured by player (owner 0)
	assert_int(target.owner_id).is_equal(0)
	# Remaining spores: 20 - 10 = 10
	assert_int(target.current_spores).is_equal(10)


## Test successful capture with exact threshold
func test_capture_at_exact_threshold():
	var target = create_test_asteroid(1, 10, 1.0)  # AI owned, 10 spores, 1.0 defense

	# Attack with 11 spores (just above 10 * 1.0 = 10 defense)
	GameManager.process_combat(11, 0, target)

	# Should be captured
	assert_int(target.owner_id).is_equal(0)
	# Remaining: 11 - 10 = 1
	assert_int(target.current_spores).is_equal(1)


## Test failed capture (insufficient force)
func test_failed_capture():
	var target = create_test_asteroid(1, 20, 1.0)  # AI owned, 20 spores, 1.0 defense

	# Attack with 15 spores (not enough to overcome 20 * 1.0 = 20 defense)
	GameManager.process_combat(15, 0, target)

	# Should remain AI owned
	assert_int(target.owner_id).is_equal(1)
	# Defender losses: 15 / 1.0 = 15, so 20 - 15 = 5 remaining
	assert_int(target.current_spores).is_equal(5)


## Test combat with high defense bonus
func test_combat_with_high_defense():
	var target = create_test_asteroid(1, 10, 2.0)  # AI owned, 10 spores, 2.0 defense

	# Effective defense: 10 * 2.0 = 20
	# Attack with 25 spores (enough to overcome 20)
	GameManager.process_combat(25, 0, target)

	# Should be captured
	assert_int(target.owner_id).is_equal(0)
	# Remaining: 25 - 20 = 5
	assert_int(target.current_spores).is_equal(5)


## Test combat with low defense bonus
func test_combat_with_low_defense():
	var target = create_test_asteroid(-1, 10, 0.5)  # Neutral, 10 spores, 0.5 defense

	# Effective defense: 10 * 0.5 = 5
	# Attack with 8 spores (enough to overcome 5)
	GameManager.process_combat(8, 1, target)

	# Should be captured by AI
	assert_int(target.owner_id).is_equal(1)
	# Remaining: 8 - 5 = 3
	assert_int(target.current_spores).is_equal(3)


## Test defender attrition (failed capture)
func test_defender_attrition():
	var target = create_test_asteroid(0, 50, 1.5)  # Player owned, 50 spores, 1.5 defense

	# Effective defense: 50 * 1.5 = 75
	# Attack with 30 spores (not enough to capture)
	GameManager.process_combat(30, 1, target)

	# Should remain player owned
	assert_int(target.owner_id).is_equal(0)
	# Defender losses: 30 / 1.5 = 20, so 50 - 20 = 30 remaining
	assert_int(target.current_spores).is_equal(30)


## Test capture of neutral asteroid with no defenders
func test_capture_neutral_no_defenders():
	var target = create_test_asteroid(-1, 0, 1.0)  # Neutral, 0 spores

	GameManager.process_combat(5, 0, target)

	# Should be captured
	assert_int(target.owner_id).is_equal(0)
	# All attackers remain: 5 - 0 = 5
	assert_int(target.current_spores).is_equal(5)


## Test edge case: 1 attacker vs 0 defenders
func test_single_attacker_vs_empty():
	var target = create_test_asteroid(-1, 0, 1.0)

	GameManager.process_combat(1, 0, target)

	assert_int(target.owner_id).is_equal(0)
	assert_int(target.current_spores).is_equal(1)


## Test edge case: equal forces with defense bonus
func test_equal_forces_with_defense():
	var target = create_test_asteroid(1, 10, 1.0)

	# Attack with exactly 10 (equal to effective defense)
	GameManager.process_combat(10, 0, target)

	# Should NOT capture (needs > not >=)
	assert_int(target.owner_id).is_equal(1)
	# Defender losses: 10 / 1.0 = 10, so 10 - 10 = 0
	assert_int(target.current_spores).is_equal(0)


## Test massive overkill attack
func test_massive_overkill():
	var target = create_test_asteroid(-1, 5, 1.0)

	GameManager.process_combat(1000, 0, target)

	assert_int(target.owner_id).is_equal(0)
	# Remaining: 1000 - 5 = 995, but capped at max_energy * 2 = 100 * 2 = 200
	assert_int(target.current_spores).is_equal(200)


## Test defender elimination (reduced to 0 spores)
func test_defender_elimination():
	var target = create_test_asteroid(1, 10, 1.0)

	# Attack with exactly enough to eliminate defenders but not capture
	GameManager.process_combat(10, 0, target)

	# Should remain AI owned (equal force doesn't capture)
	assert_int(target.owner_id).is_equal(1)
	# Should have 0 spores
	assert_int(target.current_spores).is_equal(0)


## Test very high defense bonus scenario
func test_very_high_defense_bonus():
	var target = create_test_asteroid(0, 10, 5.0)  # Very defensive asteroid

	# Effective defense: 10 * 5.0 = 50
	# Attack with 40 (not enough)
	GameManager.process_combat(40, 1, target)

	assert_int(target.owner_id).is_equal(0)
	# Losses: 40 / 5.0 = 8, so 10 - 8 = 2
	assert_int(target.current_spores).is_equal(2)


## Test fractional defense losses (rounding)
func test_fractional_defense_losses():
	var target = create_test_asteroid(1, 10, 1.5)

	# Attack with 7 spores
	# Effective defense: 10 * 1.5 = 15 (not captured)
	# Losses: 7 / 1.5 = 4.666... -> int(4.666) = 4
	GameManager.process_combat(7, 0, target)

	assert_int(target.owner_id).is_equal(1)
	# 10 - 4 = 6
	assert_int(target.current_spores).is_equal(6)


## Test minimum spores boundary (cannot go below 0)
func test_cannot_go_below_zero_spores():
	var target = create_test_asteroid(0, 5, 1.0)

	# Attack with enough to cause massive losses
	GameManager.process_combat(100, 1, target)

	# Should be captured with positive spores
	assert_int(target.owner_id).is_equal(1)
	# 100 - 5 = 95
	assert_int(target.current_spores).is_equal(95)
