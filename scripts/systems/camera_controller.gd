extends Camera2D

## Camera controller for pan and zoom
##
## Controls:
## - Mouse wheel: Zoom in/out
## - Middle mouse drag: Pan camera
## - Arrow keys: Pan camera

# Zoom settings
var zoom_speed: float = 0.1
var min_zoom: float = 0.3
var max_zoom: float = 2.0

# Pan settings
var pan_speed: float = 500.0
var is_panning: bool = false
var pan_start_position: Vector2


func _ready() -> void:
	# Enable camera
	enabled = true


func _input(event: InputEvent) -> void:
	# Zoom with mouse wheel
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP:
			_zoom_camera(1.0 + zoom_speed)
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			_zoom_camera(1.0 - zoom_speed)

		# Pan with middle mouse button
		elif event.button_index == MOUSE_BUTTON_MIDDLE:
			if event.pressed:
				is_panning = true
				pan_start_position = get_global_mouse_position()
			else:
				is_panning = false

	# Pan camera with mouse drag
	if event is InputEventMouseMotion and is_panning:
		var mouse_pos = get_global_mouse_position()
		var delta = pan_start_position - mouse_pos
		position += delta


func _process(delta: float) -> void:
	# Pan with arrow keys
	var pan_direction = Vector2.ZERO

	if Input.is_action_pressed("ui_left"):
		pan_direction.x -= 1
	if Input.is_action_pressed("ui_right"):
		pan_direction.x += 1
	if Input.is_action_pressed("ui_up"):
		pan_direction.y -= 1
	if Input.is_action_pressed("ui_down"):
		pan_direction.y += 1

	if pan_direction != Vector2.ZERO:
		position += pan_direction.normalized() * pan_speed * delta / zoom.x


## Zoom camera by given factor
func _zoom_camera(factor: float) -> void:
	var new_zoom = zoom * factor
	new_zoom.x = clamp(new_zoom.x, min_zoom, max_zoom)
	new_zoom.y = clamp(new_zoom.y, min_zoom, max_zoom)
	zoom = new_zoom
