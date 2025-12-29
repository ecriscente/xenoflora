extends Node2D
class_name SporeGroup

## Manages a group of spores traveling from one asteroid to another
##
## In Milestone 2, spores move in straight lines.
## In Milestone 5, they'll use boids flocking for organic movement.

# Target information
var source_asteroid: Asteroid
var target_asteroid: Asteroid
var owner_id: int = 0

# Spore units
var spores: Array = []  # Array of SporeUnit nodes
var spore_count: int = 0

# Movement
var travel_speed: float = 100.0  # Pixels per second (reduced for visibility)
var arrival_threshold: float = 20.0  # Distance to consider "arrived"

# References
const SPORE_UNIT_SCENE = preload("res://scenes/units/spore_unit.tscn")

# Signals
signal arrived_at_target(group)


func _ready() -> void:
	# Start moving immediately
	pass


func _process(delta: float) -> void:
	if not target_asteroid:
		return

	# Check if all spores have arrived
	var all_arrived = true

	for spore in spores:
		if is_instance_valid(spore) and not spore.has_arrived:
			all_arrived = false
			break

	if all_arrived and spores.size() > 0:
		_on_arrival()


## Initialize the spore group
func initialize(from: Asteroid, to: Asteroid, count: int, owner: int) -> void:
	source_asteroid = from
	target_asteroid = to
	spore_count = count
	owner_id = owner

	# Spawn spores
	_spawn_spores()


## Spawn individual spore units
func _spawn_spores() -> void:
	for i in spore_count:
		var spore = SPORE_UNIT_SCENE.instantiate()
		add_child(spore)

		# Position spores in a cluster around source
		var offset = Vector2(
			randf_range(-20, 20),
			randf_range(-20, 20)
		)
		spore.position = source_asteroid.position + offset
		spore.target_position = target_asteroid.position
		spore.owner_id = owner_id
		spore.travel_speed = travel_speed

		# Set spore color based on owner
		spore.set_owner_color(owner_id)

		spore.arrived.connect(_on_spore_arrived)
		spores.append(spore)


## Handle spore arrival
func _on_spore_arrived() -> void:
	# Individual spore arrived - check if all have arrived in _process
	pass


## Handle group arrival at target
func _on_arrival() -> void:
	arrived_at_target.emit(self)

	# Clean up
	queue_free()


## Get current spore count (some may be destroyed in combat later)
func get_current_count() -> int:
	var count = 0
	for spore in spores:
		if is_instance_valid(spore):
			count += 1
	return count
