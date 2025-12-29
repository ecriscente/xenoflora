extends Node

## Quick test script to verify systems work
## Run this in Godot to test basic functionality

func _ready():
	print("=== Xenoflora Test Suite ===")

	# Test 1: Check if GameManager exists
	if GameManager:
		print("✓ GameManager autoload found")
	else:
		print("✗ GameManager autoload NOT found")
		return

	# Test 2: Check if asteroid scene can load
	var asteroid_scene = load("res://scenes/asteroids/asteroid.tscn")
	if asteroid_scene:
		print("✓ Asteroid scene loads")
	else:
		print("✗ Asteroid scene failed to load")
		return

	# Test 3: Try to instantiate an asteroid
	var test_asteroid = asteroid_scene.instantiate()
	if test_asteroid:
		print("✓ Asteroid instantiates")
		add_child(test_asteroid)
		test_asteroid.position = Vector2(100, 100)
		print("  - Position: %s" % test_asteroid.position)
		print("  - Radius: %s" % test_asteroid.radius)
		print("  - Owner ID: %s" % test_asteroid.owner_id)
	else:
		print("✗ Asteroid failed to instantiate")
		return

	# Test 4: Check AsteroidGenerator
	var test_area = Rect2(-400, -300, 800, 600)
	var asteroids = AsteroidGenerator.generate_asteroids(5, test_area)
	print("✓ Generated %d asteroids" % asteroids.size())

	print("=== All Tests Passed ===")
