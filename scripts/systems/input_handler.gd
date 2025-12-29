extends Node
class_name InputHandler

## Handles player input (mouse clicks, keyboard shortcuts)
##
## Manages selection of asteroids and issuing move commands.
## Left-click: Select owned asteroid
## Right-click: Send spores to target


func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed:
		_handle_mouse_click(event)


## Handle mouse button clicks
func _handle_mouse_click(event: InputEventMouseButton) -> void:
	match event.button_index:
		MOUSE_BUTTON_LEFT:
			_handle_left_click(event.position)
		MOUSE_BUTTON_RIGHT:
			_handle_right_click(event.position)


## Handle left-click (asteroid selection)
func _handle_left_click(position: Vector2) -> void:
	# Convert screen position to world position
	var camera = get_viewport().get_camera_2d()
	var world_position = position
	if camera:
		world_position = camera.get_global_mouse_position()

	# Find asteroid at click position
	var space_state = get_viewport().world_2d.direct_space_state
	var query = PhysicsPointQueryParameters2D.new()
	query.position = world_position
	query.collide_with_areas = true

	var results = space_state.intersect_point(query, 1)

	if results.size() > 0:
		var collider = results[0].collider
		if collider is Asteroid:
			var asteroid = collider as Asteroid
			GameManager.select_asteroid(asteroid)


## Handle right-click (send spores command)
func _handle_right_click(position: Vector2) -> void:
	if not GameManager.selected_asteroid:
		return  # No asteroid selected

	# Convert screen position to world position (accounting for camera)
	var camera = get_viewport().get_camera_2d()
	var world_position = position
	if camera:
		world_position = camera.get_global_mouse_position()

	# Find target asteroid at click position
	var space_state = get_viewport().world_2d.direct_space_state
	var query = PhysicsPointQueryParameters2D.new()
	query.position = world_position
	query.collide_with_areas = true

	var results = space_state.intersect_point(query, 1)

	if results.size() > 0:
		var collider = results[0].collider
		if collider is Asteroid:
			var target = collider as Asteroid
			_send_spores_to_target(target)


## Send spores from selected asteroid to target
func _send_spores_to_target(target: Asteroid) -> void:
	var source = GameManager.selected_asteroid

	if not source:
		return

	# Send 50% of available spores
	var spore_count = int(source.current_spores / 2.0)

	if spore_count <= 0:
		push_warning("InputHandler: Not enough spores to send")
		return

	# Send spores via GameManager
	GameManager.send_spores(source, target, spore_count)
