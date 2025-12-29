extends Node

## Global game manager (Autoload singleton)
##
## Coordinates all game systems, manages state, and handles game loop.
## Acts as the central hub for communication between systems.

# Preload scenes
const SPORE_GROUP_SCENE = preload("res://scripts/entities/spore_group.gd")

# Game state
var asteroids: Array[Asteroid] = []
var spore_groups: Array = []  # Array of SporeGroup nodes
var current_player: int = 0  # 0 = player, 1 = AI
var selected_asteroid: Asteroid = null

# Game settings
var asteroid_count: int = 15
var play_area: Rect2 = Rect2(-800, -400, 1600, 800)

# Node references (set by main scene)
var asteroid_container: Node2D = null
var spore_container: Node2D = null

# Signals
signal game_initialized()
signal asteroid_selected(asteroid: Asteroid)
signal asteroid_deselected()
signal spores_sent(from: Asteroid, to: Asteroid, count: int)
signal asteroid_captured(asteroid: Asteroid, new_owner: int)
signal game_over(winner: int)


func _ready() -> void:
	pass  # GameManager initialized


## Initialize the game with procedurally generated asteroids
func initialize_game(count: int = 15) -> void:
	# Clear existing state
	asteroids.clear()
	spore_groups.clear()
	selected_asteroid = null

	# Generate asteroids
	asteroids = AsteroidGenerator.generate_asteroids(count, play_area)

	# Assign starting positions
	var starting = AsteroidGenerator.assign_starting_asteroids(asteroids)

	# Add asteroids to scene if container is set
	if asteroid_container:
		for asteroid in asteroids:
			asteroid_container.add_child(asteroid)
			# Connect to asteroid signals
			asteroid.clicked.connect(_on_asteroid_clicked)
			asteroid.owner_changed.connect(_on_asteroid_owner_changed)

	game_initialized.emit()


## Handle asteroid selection
func select_asteroid(asteroid: Asteroid) -> void:
	# Deselect previous
	if selected_asteroid:
		selected_asteroid.deselect()
		asteroid_deselected.emit()

	# Select new (only if player-owned)
	if asteroid.owner_id == 0:
		selected_asteroid = asteroid
		asteroid.select()
		asteroid_selected.emit(asteroid)
	else:
		selected_asteroid = null


## Send spores from one asteroid to another
func send_spores(from: Asteroid, to: Asteroid, count: int) -> void:
	if from.current_spores < count:
		push_warning("GameManager: Not enough spores (%d/%d)" % [from.current_spores, count])
		return

	# Deduct spores from source
	from.current_spores -= count

	# Create SporeGroup
	var spore_group = Node2D.new()
	spore_group.set_script(SPORE_GROUP_SCENE)

	if spore_container:
		spore_container.add_child(spore_group)
		spore_group.initialize(from, to, count, from.owner_id)
		spore_group.arrived_at_target.connect(_on_spore_group_arrived)
		spore_groups.append(spore_group)

	spores_sent.emit(from, to, count)


## Process combat when spores arrive at target
func process_combat(attacker_count: int, attacker_owner: int, target: Asteroid) -> void:
	var defender_count = target.current_spores
	var defender_bonus = target.get_effective_defense()  # Include tree bonuses
	var effective_defense = defender_count * defender_bonus

	if attacker_count > effective_defense:
		# Capture!
		var remaining = int(attacker_count - effective_defense)
		target.change_owner(attacker_owner)
		target.current_spores = remaining
		asteroid_captured.emit(target, attacker_owner)
	else:
		# Defense holds - defenders lose spores equal to attackers / defense_bonus
		var losses = int(attacker_count / defender_bonus)
		var remaining = max(0, defender_count - losses)
		target.current_spores = remaining


## Serialize current game state to dictionary (for save/load and networking)
func serialize_state() -> Dictionary:
	var asteroid_data: Array = []
	for asteroid in asteroids:
		asteroid_data.append(asteroid.to_dict())

	return {
		"version": "0.1.0",
		"asteroids": asteroid_data,
		"current_player": current_player,
		"timestamp": Time.get_unix_time_from_system()
	}


## Restore game state from dictionary
func deserialize_state(data: Dictionary) -> void:
	# TODO: Implement full deserialization
	pass


## Check win/loss conditions
func check_game_over() -> void:
	var player_asteroids = 0
	var ai_asteroids = 0

	for asteroid in asteroids:
		if asteroid.owner_id == 0:
			player_asteroids += 1
		elif asteroid.owner_id == 1:
			ai_asteroids += 1

	if player_asteroids == 0:
		game_over.emit(1)
	elif ai_asteroids == 0:
		game_over.emit(0)


## Handle spore group arrival at target
func _on_spore_group_arrived(group) -> void:
	# Remove from tracking
	spore_groups.erase(group)

	var attacker_count = group.get_current_count()
	var attacker_owner = group.owner_id
	var target = group.target_asteroid

	# Check if friendly reinforcement or enemy attack
	if attacker_owner == target.owner_id:
		# Friendly reinforcement - just add spores
		target.current_spores += attacker_count
	else:
		# Enemy target - process combat
		process_combat(attacker_count, attacker_owner, target)


## Handle asteroid click events
func _on_asteroid_clicked(asteroid: Asteroid) -> void:
	# Handle asteroid selection on click
	select_asteroid(asteroid)


## Handle asteroid ownership changes
func _on_asteroid_owner_changed(new_owner: int) -> void:
	check_game_over()
