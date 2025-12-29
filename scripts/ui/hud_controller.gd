extends CanvasLayer

## HUD Controller - Display game stats and selected asteroid info
##
## Milestone 7: Game Loop & Polish

@onready var selected_info: Label = $SelectedInfo
@onready var stats_label: Label = $StatsLabel
@onready var game_over_panel: Panel = $GameOverPanel
@onready var game_over_label: Label = $GameOverPanel/GameOverLabel
@onready var restart_button: Button = $GameOverPanel/RestartButton

@onready var planting_panel: Panel = $PlantingPanel
@onready var tree_info_label: Label = $PlantingPanel/TreeInfoLabel
@onready var plant_production_button: Button = $PlantingPanel/PlantProductionButton
@onready var plant_defense_button: Button = $PlantingPanel/PlantDefenseButton
@onready var plant_speed_button: Button = $PlantingPanel/PlantSpeedButton

var selected_asteroid: Asteroid = null


func _ready() -> void:
	# Connect to game events
	GameManager.asteroid_selected.connect(_on_asteroid_selected)
	GameManager.asteroid_deselected.connect(_on_asteroid_deselected)
	GameManager.game_over.connect(_on_game_over)

	# Hide game over panel initially
	if game_over_panel:
		game_over_panel.visible = false

	# Connect restart button
	if restart_button:
		restart_button.pressed.connect(_on_restart_pressed)

	# Connect planting buttons
	if plant_production_button:
		plant_production_button.pressed.connect(_on_plant_production)
	if plant_defense_button:
		plant_defense_button.pressed.connect(_on_plant_defense)
	if plant_speed_button:
		plant_speed_button.pressed.connect(_on_plant_speed)

	# Hide planting panel initially
	if planting_panel:
		planting_panel.visible = false

	_update_stats()


func _process(_delta: float) -> void:
	# Update stats every frame
	_update_stats()


func _unhandled_input(event: InputEvent) -> void:
	if not selected_asteroid or selected_asteroid.owner_id != 0:
		return

	if event is InputEventKey and event.pressed and not event.echo:
		match event.keycode:
			KEY_P:
				_on_plant_production()
				get_viewport().set_input_as_handled()
			KEY_D:
				_on_plant_defense()
				get_viewport().set_input_as_handled()
			KEY_S:
				_on_plant_speed()
				get_viewport().set_input_as_handled()


func _update_stats() -> void:
	if not stats_label:
		return

	# Count asteroids by owner
	var player_count = 0
	var ai_count = 0
	var neutral_count = 0

	for asteroid in GameManager.asteroids:
		match asteroid.owner_id:
			0:
				player_count += 1
			1:
				ai_count += 1
			-1:
				neutral_count += 1

	stats_label.text = "Player: %d | AI: %d | Neutral: %d" % [player_count, ai_count, neutral_count]


func _on_asteroid_selected(asteroid: Asteroid) -> void:
	selected_asteroid = asteroid

	if not selected_info:
		return

	var owner_text = "Neutral"
	match asteroid.owner_id:
		0:
			owner_text = "Player"
		1:
			owner_text = "AI"

	selected_info.text = "Selected: %s | Spores: %d | Energy: %.0f | Defense: %.1fx" % [
		owner_text,
		asteroid.current_spores,
		asteroid.max_energy,
		asteroid.defense_bonus
	]
	selected_info.visible = true

	# Show planting panel for player asteroids
	if asteroid.owner_id == 0 and planting_panel:
		planting_panel.visible = true
		_update_planting_buttons()


func _on_asteroid_deselected() -> void:
	selected_asteroid = null
	if selected_info:
		selected_info.visible = false
	if planting_panel:
		planting_panel.visible = false


func _on_game_over(winner: int) -> void:
	if not game_over_panel or not game_over_label:
		return

	# Show game over panel
	game_over_panel.visible = true

	# Set message based on winner
	if winner == 0:
		game_over_label.text = "VICTORY!\nYou conquered all asteroids!"
		game_over_label.add_theme_color_override("font_color", Color(0.09, 0.77, 1.0))  # Cyan
	else:
		game_over_label.text = "DEFEAT!\nThe AI has conquered your asteroids."
		game_over_label.add_theme_color_override("font_color", Color(0.97, 0.44, 0.44))  # Red


func _on_restart_pressed() -> void:
	# Unpause first
	get_tree().paused = false

	# Use call_deferred to reload after current frame
	get_tree().call_deferred("reload_current_scene")


## ===== Tree Planting Methods =====

func _update_planting_buttons() -> void:
	if not selected_asteroid or not planting_panel:
		return

	var can_plant = selected_asteroid.can_plant_tree()

	if plant_production_button:
		plant_production_button.disabled = not can_plant
	if plant_defense_button:
		plant_defense_button.disabled = not can_plant
	if plant_speed_button:
		plant_speed_button.disabled = not can_plant

	if tree_info_label:
		tree_info_label.text = "Trees: %d/%d" % [
			selected_asteroid.trees.size(),
			selected_asteroid.get_max_trees()
		]


func _on_plant_production() -> void:
	if selected_asteroid and selected_asteroid.plant_tree(0):  # PRODUCTION
		_update_planting_buttons()
		# Hide panel after successful plant
		if planting_panel:
			planting_panel.visible = false


func _on_plant_defense() -> void:
	if selected_asteroid and selected_asteroid.plant_tree(1):  # DEFENSE
		_update_planting_buttons()
		# Hide panel after successful plant
		if planting_panel:
			planting_panel.visible = false


func _on_plant_speed() -> void:
	if selected_asteroid and selected_asteroid.plant_tree(2):  # SPEED
		_update_planting_buttons()
		# Hide panel after successful plant
		if planting_panel:
			planting_panel.visible = false
