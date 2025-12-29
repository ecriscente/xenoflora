extends Node2D
class_name SporeUnit

## Individual spore unit with movement behavior
##
## Milestone 2: Simple straight-line movement
## Milestone 5: Boids flocking (separation, alignment, cohesion)

# Movement
var velocity: Vector2 = Vector2.ZERO
var target_position: Vector2 = Vector2.ZERO
var travel_speed: float = 150.0
var has_arrived: bool = false

# Owner
var owner_id: int = 0

# Arrival threshold
var arrival_distance: float = 10.0

# Node references
@onready var sprite: Sprite2D = $Sprite2D

# Signals
signal arrived()


func _ready() -> void:
	# Set initial velocity toward target
	if target_position != Vector2.ZERO:
		var direction = (target_position - position).normalized()
		velocity = direction * travel_speed


func _process(delta: float) -> void:
	if has_arrived:
		return

	# Simple straight-line movement (Milestone 2)
	move_toward_target_simple(delta)

	# Check if arrived
	var distance = position.distance_to(target_position)
	if distance <= arrival_distance:
		_arrive()


## Simple movement toward target (straight line)
func move_toward_target_simple(delta: float) -> void:
	var direction = (target_position - position).normalized()
	velocity = direction * travel_speed
	position += velocity * delta


## Apply boids flocking behavior (Milestone 5 - not yet implemented)
func apply_boids(_neighbors: Array, _delta: float) -> void:
	# TODO: Implement in Milestone 5
	# Will calculate separation, alignment, cohesion forces
	pass


## Handle arrival at target
func _arrive() -> void:
	has_arrived = true
	arrived.emit()
	# Don't free yet - parent SporeGroup will handle cleanup


## Set sprite color based on owner
func set_owner_color(owner: int) -> void:
	if not sprite:
		return

	match owner:
		0:  # Player - Cyan
			sprite.modulate = Color(0.09, 0.77, 1.0)
		1:  # AI - Red
			sprite.modulate = Color(0.97, 0.44, 0.44)
		_:  # Neutral - Gray
			sprite.modulate = Color(0.5, 0.5, 0.5)
