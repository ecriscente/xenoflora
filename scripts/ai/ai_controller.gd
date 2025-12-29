extends Node
class_name AIController

## AI Controller - Aggressive greedy strategy
##
## Milestone 6: AI Opponent
## - Attacks from EVERY conquered asteroid
## - Very aggressive threshold (0.9x required spores)
## - Targets closest weak player asteroids
## - Acts every 2 seconds
## - Sends 60% of spores per attack

# AI configuration
const ATTACK_THRESHOLD_MULTIPLIER: float = 0.9  # Lower = more aggressive (attack even without full coverage)
const AI_TURN_INTERVAL: float = 2.0  # Seconds between AI actions
const MIN_SPORES_TO_ATTACK: int = 8  # Minimum spores needed to consider attacking
const SPORE_SEND_PERCENTAGE: float = 0.6  # Send 60% of spores per attack

# AI turn timer
var turn_timer: float = 0.0


func _ready() -> void:
	pass  # AI ready


func _process(delta: float) -> void:
	turn_timer += delta

	if turn_timer >= AI_TURN_INTERVAL:
		turn_timer = 0.0
		_take_turn()


## AI takes its turn (evaluate and potentially attack)
func _take_turn() -> void:
	var ai_asteroids = _get_ai_asteroids()
	var player_asteroids = _get_player_asteroids()

	if ai_asteroids.size() == 0 or player_asteroids.size() == 0:
		return  # Can't act if no asteroids

	# Attack from EVERY AI asteroid that has enough spores
	for attacker in ai_asteroids:
		# Skip asteroids with too few spores
		if attacker.current_spores < MIN_SPORES_TO_ATTACK:
			continue

		# Find best target for this attacker
		var target = _find_best_target_for_attacker(attacker, player_asteroids)
		if not target:
			continue

		# Calculate required spores to capture
		var required_spores = _calculate_required_spores(target)

		# Check if we have enough (very aggressive threshold)
		var attack_threshold = required_spores * ATTACK_THRESHOLD_MULTIPLIER
		if attacker.current_spores >= attack_threshold:
			# Attack! Send configured percentage of available spores
			var send_count = int(attacker.current_spores * SPORE_SEND_PERCENTAGE)
			if send_count > 0:
				GameManager.send_spores(attacker, target, send_count)


## Get all AI-owned asteroids
func _get_ai_asteroids() -> Array[Asteroid]:
	var result: Array[Asteroid] = []
	for asteroid in GameManager.asteroids:
		if asteroid.owner_id == 1:  # AI = 1
			result.append(asteroid)
	return result


## Get all player-owned asteroids
func _get_player_asteroids() -> Array[Asteroid]:
	var result: Array[Asteroid] = []
	for asteroid in GameManager.asteroids:
		if asteroid.owner_id == 0:  # Player = 0
			result.append(asteroid)
	return result


## Find weakest asteroid (lowest total defense)
func _find_weakest_asteroid(asteroids: Array[Asteroid]) -> Asteroid:
	if asteroids.size() == 0:
		return null

	var weakest = asteroids[0]
	var min_defense = weakest.current_spores * weakest.defense_bonus

	for asteroid in asteroids:
		var defense = asteroid.current_spores * asteroid.defense_bonus
		if defense < min_defense:
			min_defense = defense
			weakest = asteroid

	return weakest


## Find best target for a specific attacker (closest weak asteroid)
func _find_best_target_for_attacker(attacker: Asteroid, targets: Array[Asteroid]) -> Asteroid:
	if targets.size() == 0:
		return null

	var best_target = null
	var best_score = -1.0

	for target in targets:
		# Calculate distance
		var distance = attacker.position.distance_to(target.position)

		# Calculate defense strength
		var defense = target.current_spores * target.defense_bonus

		# Score: prefer closer and weaker targets (lower is better)
		# Normalize distance (assume max ~1000) and defense (assume max ~200)
		var score = (distance / 1000.0) + (defense / 200.0)

		if best_target == null or score < best_score:
			best_score = score
			best_target = target

	return best_target


## Calculate spores needed to capture target
func _calculate_required_spores(target: Asteroid) -> int:
	var defender_count = target.current_spores
	var defender_bonus = target.defense_bonus
	var effective_defense = defender_count * defender_bonus

	# Need to exceed effective defense
	return int(effective_defense) + 1
