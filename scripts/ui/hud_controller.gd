extends CanvasLayer

## HUD Controller - Display game stats and selected asteroid info
##
## Milestone 7: Game Loop & Polish

@onready var selected_info: Label = $SelectedInfo
@onready var stats_label: Label = $StatsLabel
@onready var game_over_panel: Panel = $GameOverPanel
@onready var game_over_label: Label = $GameOverPanel/GameOverLabel
@onready var restart_button: Button = $GameOverPanel/RestartButton


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

	_update_stats()


func _process(_delta: float) -> void:
	# Update stats every frame
	_update_stats()


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


func _on_asteroid_deselected() -> void:
	if selected_info:
		selected_info.visible = false


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
