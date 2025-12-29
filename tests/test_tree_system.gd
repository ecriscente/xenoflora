extends GdUnitTestSuite

## Unit tests for the Tree and Asteroid tree system
##
## Tests tree planting, growth, bonuses, and serialization

# Helper function to create a test asteroid
func create_test_asteroid(owner: int, spores: int) -> Asteroid:
	var asteroid = Asteroid.new()
	asteroid.owner_id = owner
	asteroid.current_spores = spores
	asteroid.max_energy = 100.0
	asteroid.defense_bonus = 1.0
	asteroid.speed_bonus = 1.0
	asteroid.radius = 50.0
	return asteroid


## ===== Tree Class Tests =====

func test_tree_initialization():
	var tree = PlantedTree.new()
	tree.tree_type = 0  # PRODUCTION
	assert_int(tree.tree_type).is_equal(0)  # PRODUCTION
	assert_int(tree.growth_stage).is_equal(0)  # SAPLING
	assert_float(tree.growth_timer).is_equal(0.0)


func test_tree_growth_progression():
	var tree = PlantedTree.new()
	tree.tree_type = 1  # DEFENSE

	# Test growth from SAPLING to YOUNG (7.5 seconds)
	assert_bool(tree.update_growth(7.4)).is_false()
	assert_int(tree.growth_stage).is_equal(0)  # SAPLING

	assert_bool(tree.update_growth(0.1)).is_true()
	assert_int(tree.growth_stage).is_equal(1)  # YOUNG

	# Test growth from YOUNG to MATURE
	assert_bool(tree.update_growth(7.5)).is_true()
	assert_int(tree.growth_stage).is_equal(2)  # MATURE

	# Test growth from MATURE to ANCIENT
	assert_bool(tree.update_growth(7.5)).is_true()
	assert_int(tree.growth_stage).is_equal(3)  # ANCIENT

	# Test that ANCIENT doesn't grow further
	assert_bool(tree.update_growth(10.0)).is_false()
	assert_int(tree.growth_stage).is_equal(3)  # ANCIENT


func test_tree_is_mature():
	var tree = PlantedTree.new()
	tree.tree_type = 2  # SPEED

	assert_bool(tree.is_mature()).is_false()  # SAPLING

	tree.growth_stage = 1  # YOUNG
	assert_bool(tree.is_mature()).is_false()  # YOUNG

	tree.growth_stage = 2  # MATURE
	assert_bool(tree.is_mature()).is_true()  # MATURE

	tree.growth_stage = 3  # ANCIENT
	assert_bool(tree.is_mature()).is_true()  # ANCIENT


func test_tree_bonus_values():
	var prod_tree = PlantedTree.new()
	prod_tree.tree_type = 0  # PRODUCTION
	var def_tree = PlantedTree.new()
	def_tree.tree_type = 1  # DEFENSE
	var speed_tree = PlantedTree.new()
	speed_tree.tree_type = 2  # SPEED

	# No bonus when not mature
	assert_float(prod_tree.get_bonus_value()).is_equal(0.0)
	assert_float(def_tree.get_bonus_value()).is_equal(0.0)
	assert_float(speed_tree.get_bonus_value()).is_equal(0.0)

	# Bonuses when mature
	prod_tree.growth_stage = 2  # MATURE
	def_tree.growth_stage = 2  # MATURE
	speed_tree.growth_stage = 2  # MATURE

	assert_float(prod_tree.get_bonus_value()).is_equal(0.5)
	assert_float(def_tree.get_bonus_value()).is_equal(0.5)
	assert_float(speed_tree.get_bonus_value()).is_equal_approx(0.3, 0.001)


func test_tree_serialization():
	var tree = PlantedTree.new()
	tree.tree_type = 1  # DEFENSE
	tree.growth_stage = 1  # YOUNG
	tree.growth_timer = 3.5
	tree.position_offset = Vector2(25.0, 10.0)

	var data = tree.to_dict()
	assert_int(data.type).is_equal(1)  # DEFENSE
	assert_int(data.stage).is_equal(1)  # YOUNG
	assert_float(data.timer).is_equal(3.5)
	assert_float(data.offset.x).is_equal(25.0)
	assert_float(data.offset.y).is_equal(10.0)

	# Test deserialization
	var restored = PlantedTree.new()
	restored.restore_from_dict(data)
	assert_int(restored.tree_type).is_equal(1)  # DEFENSE
	assert_int(restored.growth_stage).is_equal(1)  # YOUNG
	assert_float(restored.growth_timer).is_equal(3.5)
	assert_float(restored.position_offset.x).is_equal(25.0)
	assert_float(restored.position_offset.y).is_equal(10.0)


## ===== Asteroid Tree Integration Tests =====

func test_get_max_trees_based_on_energy():
	var asteroid = create_test_asteroid(0, 100)

	asteroid.max_energy = 50.0
	assert_int(asteroid.get_max_trees()).is_equal(1)

	asteroid.max_energy = 100.0
	assert_int(asteroid.get_max_trees()).is_equal(2)

	asteroid.max_energy = 150.0
	assert_int(asteroid.get_max_trees()).is_equal(3)

	asteroid.max_energy = 149.0
	assert_int(asteroid.get_max_trees()).is_equal(2)


func test_can_plant_tree_requires_player_ownership():
	var asteroid = create_test_asteroid(1, 100)  # AI owned
	assert_bool(asteroid.can_plant_tree()).is_false()

	asteroid.owner_id = -1  # Neutral
	assert_bool(asteroid.can_plant_tree()).is_false()

	asteroid.owner_id = 0  # Player owned
	assert_bool(asteroid.can_plant_tree()).is_true()


func test_can_plant_tree_requires_sufficient_spores():
	var asteroid = create_test_asteroid(0, 19)
	assert_bool(asteroid.can_plant_tree()).is_false()

	asteroid.current_spores = 20
	assert_bool(asteroid.can_plant_tree()).is_true()

	asteroid.current_spores = 100
	assert_bool(asteroid.can_plant_tree()).is_true()


func test_can_plant_tree_respects_max_limit():
	var asteroid = create_test_asteroid(0, 100)
	asteroid.max_energy = 100.0  # Max 2 trees

	assert_bool(asteroid.can_plant_tree()).is_true()

	asteroid.plant_tree(0)  # PRODUCTION
	assert_bool(asteroid.can_plant_tree()).is_true()

	asteroid.plant_tree(1)  # DEFENSE
	assert_bool(asteroid.can_plant_tree()).is_false()  # Limit reached


func test_plant_tree_costs_spores():
	var asteroid = create_test_asteroid(0, 50)

	asteroid.plant_tree(0)  # PRODUCTION
	assert_int(asteroid.current_spores).is_equal(30)

	asteroid.plant_tree(1)  # DEFENSE
	assert_int(asteroid.current_spores).is_equal(10)


func test_plant_tree_adds_to_trees_array():
	var asteroid = create_test_asteroid(0, 100)

	assert_int(asteroid.trees.size()).is_equal(0)

	asteroid.plant_tree(0)  # PRODUCTION
	assert_int(asteroid.trees.size()).is_equal(1)
	assert_int(asteroid.trees[0].tree_type).is_equal(0)  # PRODUCTION

	asteroid.plant_tree(2)  # SPEED
	assert_int(asteroid.trees.size()).is_equal(2)
	assert_int(asteroid.trees[1].tree_type).is_equal(2)  # SPEED


func test_plant_tree_fails_without_requirements():
	var asteroid = create_test_asteroid(0, 10)  # Insufficient spores

	assert_bool(asteroid.plant_tree(0)).is_false()  # PRODUCTION
	assert_int(asteroid.trees.size()).is_equal(0)
	assert_int(asteroid.current_spores).is_equal(10)  # Spores not deducted


func test_production_bonus_from_mature_tree():
	var asteroid = create_test_asteroid(0, 100)

	# No trees - base multiplier
	assert_float(asteroid.get_production_multiplier()).is_equal(1.0)

	# Plant production tree but not mature yet
	asteroid.plant_tree(0)  # PRODUCTION
	assert_float(asteroid.get_production_multiplier()).is_equal(1.0)

	# Mature the tree
	asteroid.trees[0].growth_stage = 2  # MATURE
	assert_float(asteroid.get_production_multiplier()).is_equal(1.5)  # 1.0 + 0.5


func test_production_bonus_stacks():
	var asteroid = create_test_asteroid(0, 100)
	asteroid.max_energy = 150.0  # Allow 3 trees

	asteroid.plant_tree(0)  # PRODUCTION
	asteroid.plant_tree(0)  # PRODUCTION
	asteroid.plant_tree(0)  # PRODUCTION

	# Make all trees mature
	for tree in asteroid.trees:
		tree.growth_stage = 3  # ANCIENT

	assert_float(asteroid.get_production_multiplier()).is_equal(2.5)  # 1.0 + 0.5 + 0.5 + 0.5


func test_defense_bonus_from_mature_tree():
	var asteroid = create_test_asteroid(0, 100)
	asteroid.defense_bonus = 1.0

	# No trees - base defense
	assert_float(asteroid.get_effective_defense()).is_equal(1.0)

	# Plant defense tree but not mature yet
	asteroid.plant_tree(1)  # DEFENSE
	assert_float(asteroid.get_effective_defense()).is_equal(1.0)

	# Mature the tree
	asteroid.trees[0].growth_stage = 2  # MATURE
	assert_float(asteroid.get_effective_defense()).is_equal(1.5)  # 1.0 + 0.5


func test_defense_bonus_stacks():
	var asteroid = create_test_asteroid(0, 100)
	asteroid.max_energy = 150.0  # Allow 3 trees
	asteroid.defense_bonus = 1.0

	asteroid.plant_tree(1)  # DEFENSE
	asteroid.plant_tree(1)  # DEFENSE

	for tree in asteroid.trees:
		tree.growth_stage = 2  # MATURE

	assert_float(asteroid.get_effective_defense()).is_equal(2.0)  # 1.0 + 0.5 + 0.5


func test_speed_bonus_from_mature_tree():
	var asteroid = create_test_asteroid(0, 100)
	asteroid.speed_bonus = 1.0

	# No trees - base speed
	assert_float(asteroid.get_speed_multiplier()).is_equal(1.0)

	# Plant speed tree but not mature yet
	asteroid.plant_tree(2)  # SPEED
	assert_float(asteroid.get_speed_multiplier()).is_equal(1.0)

	# Mature the tree
	asteroid.trees[0].growth_stage = 2  # MATURE
	assert_float(asteroid.get_speed_multiplier()).is_equal_approx(1.3, 0.001)  # 1.0 + 0.3


func test_speed_bonus_stacks():
	var asteroid = create_test_asteroid(0, 100)
	asteroid.max_energy = 150.0  # Allow 3 trees
	asteroid.speed_bonus = 1.0

	asteroid.plant_tree(2)  # SPEED
	asteroid.plant_tree(2)  # SPEED
	asteroid.plant_tree(2)  # SPEED

	for tree in asteroid.trees:
		tree.growth_stage = 3  # ANCIENT

	assert_float(asteroid.get_speed_multiplier()).is_equal_approx(1.9, 0.001)  # 1.0 + 0.3 + 0.3 + 0.3


func test_mixed_tree_types_provide_correct_bonuses():
	var asteroid = create_test_asteroid(0, 100)
	asteroid.max_energy = 150.0
	asteroid.defense_bonus = 1.0
	asteroid.speed_bonus = 1.0

	asteroid.plant_tree(0)  # PRODUCTION
	asteroid.plant_tree(1)  # DEFENSE
	asteroid.plant_tree(2)  # SPEED

	for tree in asteroid.trees:
		tree.growth_stage = 2  # MATURE

	assert_float(asteroid.get_production_multiplier()).is_equal(1.5)
	assert_float(asteroid.get_effective_defense()).is_equal(1.5)
	assert_float(asteroid.get_speed_multiplier()).is_equal_approx(1.3, 0.001)


func test_asteroid_serialization_with_trees():
	var asteroid = create_test_asteroid(0, 50)
	asteroid.max_energy = 100.0
	asteroid.plant_tree(0)  # PRODUCTION
	asteroid.plant_tree(1)  # DEFENSE

	asteroid.trees[0].growth_stage = 2  # MATURE
	asteroid.trees[1].growth_stage = 1  # YOUNG

	var data = asteroid.to_dict()

	assert_bool(data.has("trees")).is_true()
	assert_int(data.trees.size()).is_equal(2)
	assert_int(data.trees[0].type).is_equal(0)  # PRODUCTION
	assert_int(data.trees[0].stage).is_equal(2)  # MATURE
	assert_int(data.trees[1].type).is_equal(1)  # DEFENSE
	assert_int(data.trees[1].stage).is_equal(1)  # YOUNG


func test_clear_all_trees_on_ownership_change():
	var asteroid = create_test_asteroid(0, 100)
	asteroid.max_energy = 150.0

	asteroid.plant_tree(0)  # PRODUCTION
	asteroid.plant_tree(1)  # DEFENSE
	asteroid.plant_tree(2)  # SPEED

	assert_int(asteroid.trees.size()).is_equal(3)

	# Change ownership
	asteroid.change_owner(1)  # Transfer to AI

	# Trees should be cleared
	assert_int(asteroid.trees.size()).is_equal(0)


func test_tree_positioning_around_asteroid():
	var asteroid = create_test_asteroid(0, 100)
	asteroid.max_energy = 100.0  # Max 2 trees
	asteroid.radius = 50.0

	var pos0 = asteroid._get_tree_position(0)
	var pos1 = asteroid._get_tree_position(1)

	# Positions should be different
	assert_bool(pos0 != pos1).is_true()

	# Positions should be at radius + 30 distance
	var distance0 = pos0.length()
	var distance1 = pos1.length()
	assert_float(distance0).is_equal_approx(80.0, 0.01)  # 50 + 30
	assert_float(distance1).is_equal_approx(80.0, 0.01)


## ===== Edge Cases =====

func test_plant_tree_with_exactly_20_spores():
	var asteroid = create_test_asteroid(0, 20)

	assert_bool(asteroid.plant_tree(0)).is_true()  # PRODUCTION
	assert_int(asteroid.current_spores).is_equal(0)
	assert_int(asteroid.trees.size()).is_equal(1)


func test_cannot_plant_tree_as_neutral():
	var asteroid = create_test_asteroid(-1, 100)

	assert_bool(asteroid.can_plant_tree()).is_false()
	assert_bool(asteroid.plant_tree(0)).is_false()  # PRODUCTION


func test_cannot_plant_tree_as_ai():
	var asteroid = create_test_asteroid(1, 100)

	assert_bool(asteroid.can_plant_tree()).is_false()
	assert_bool(asteroid.plant_tree(0)).is_false()  # PRODUCTION


func test_asteroid_with_zero_energy_has_no_tree_slots():
	var asteroid = create_test_asteroid(0, 100)
	asteroid.max_energy = 0.0

	assert_int(asteroid.get_max_trees()).is_equal(0)
	assert_bool(asteroid.can_plant_tree()).is_false()


func test_asteroid_with_low_energy_has_limited_slots():
	var asteroid = create_test_asteroid(0, 100)
	asteroid.max_energy = 49.0

	assert_int(asteroid.get_max_trees()).is_equal(0)

	asteroid.max_energy = 50.0
	assert_int(asteroid.get_max_trees()).is_equal(1)
