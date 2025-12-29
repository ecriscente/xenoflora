extends Node2D

## Game World script
##
## Initializes the game world and connects GameManager to scene nodes.

@onready var asteroid_container: Node2D = $AsteroidContainer
@onready var spore_container: Node2D = $SporeContainer


func _ready() -> void:
	# Connect GameManager to scene containers
	GameManager.asteroid_container = asteroid_container
	GameManager.spore_container = spore_container

	# Wait for scene to be fully loaded
	await get_tree().process_frame

	# Initialize game
	GameManager.initialize_game(15)

	# Connect to game events
	GameManager.asteroid_selected.connect(_on_asteroid_selected)
	GameManager.asteroid_deselected.connect(_on_asteroid_deselected)


func _on_asteroid_selected(asteroid: Asteroid) -> void:
	pass  # Asteroid selected


func _on_asteroid_deselected() -> void:
	pass  # Asteroid deselected
