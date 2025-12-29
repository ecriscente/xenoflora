extends Node2D
class_name SporeUnit

## Individual spore unit with movement behavior
##
## Milestone 2: Simple straight-line movement
## Milestone 5: Boids flocking (separation, alignment, cohesion)

# Boids configuration
const BOIDS_WEIGHTS = {
	"separation": 1.8,
	"alignment": 0.8,
	"cohesion": 1.2,
	"target": 3.0,
}
const MAX_FORCE: float = 400.0
const MIN_SEPARATION_DISTANCE: float = 20.0

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


func _process(_delta: float) -> void:
	if has_arrived:
		return

	# BoidsSystem handles movement via apply_boids()
	# Just check arrival locally for immediate response
	var distance = position.distance_to(target_position)
	if distance <= arrival_distance:
		_arrive()


## Simple movement toward target (straight line)
func move_toward_target_simple(delta: float) -> void:
	var direction = (target_position - position).normalized()
	velocity = direction * travel_speed
	position += velocity * delta


## Apply boids flocking behavior (Phase 2+)
func apply_boids(neighbors: Array, delta: float) -> void:
	# Calculate all forces
	var separation = _calculate_separation(neighbors)
	var alignment = _calculate_alignment(neighbors)
	var cohesion = _calculate_cohesion(neighbors)
	var targeting = _calculate_targeting()

	# Combined steering
	var steering = (
		separation * BOIDS_WEIGHTS.separation +
		alignment * BOIDS_WEIGHTS.alignment +
		cohesion * BOIDS_WEIGHTS.cohesion +
		targeting * BOIDS_WEIGHTS.target
	)

	# Limit steering force
	if steering.length() > MAX_FORCE:
		steering = steering.normalized() * MAX_FORCE

	# Update velocity
	velocity += steering * delta

	# Clamp to max speed
	if velocity.length() > travel_speed:
		velocity = velocity.normalized() * travel_speed

	# Update position
	position += velocity * delta


## Calculate targeting force (seek destination)
func _calculate_targeting() -> Vector2:
	return _seek_position(target_position)


## Seek a specific position
func _seek_position(target: Vector2) -> Vector2:
	var desired = (target - position).normalized() * travel_speed
	return desired - velocity


## Calculate separation force (avoid crowding)
func _calculate_separation(neighbors: Array) -> Vector2:
	var steer = Vector2.ZERO
	var count = 0

	for neighbor in neighbors:
		var dist = position.distance_to(neighbor.position)

		if dist < MIN_SEPARATION_DISTANCE and dist > 0:
			# Push away from neighbor, stronger when closer
			var diff = (position - neighbor.position).normalized()
			diff /= dist  # Weight by distance (closer = stronger)
			steer += diff
			count += 1

	if count > 0:
		steer /= count  # Average the force
		steer = steer.normalized() * travel_speed
		steer -= velocity  # Steering = desired - current

	return steer


## Calculate alignment force (match velocity with neighbors)
func _calculate_alignment(neighbors: Array) -> Vector2:
	var avg_vel = Vector2.ZERO

	for neighbor in neighbors:
		avg_vel += neighbor.velocity

	if neighbors.size() > 0:
		avg_vel /= neighbors.size()
		avg_vel = avg_vel.normalized() * travel_speed
		return avg_vel - velocity

	return Vector2.ZERO


## Calculate cohesion force (move toward group center)
func _calculate_cohesion(neighbors: Array) -> Vector2:
	var center = Vector2.ZERO

	for neighbor in neighbors:
		center += neighbor.position

	if neighbors.size() > 0:
		center /= neighbors.size()
		return _seek_position(center)

	return Vector2.ZERO


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
