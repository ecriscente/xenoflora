extends Area2D
class_name Asteroid

## Asteroid node representing a colonizable celestial body
##
## Asteroids are the core strategic points in Xenoflora. They can be captured
## by overwhelming them with spores and produce new spores over time when owned.

# Exported properties (can be set in editor or on instantiation)
@export var max_energy: float = 100.0 ## Maximum energy capacity, affects production cap
@export var defense_bonus: float = 1.0 ## Defensive multiplier, affects production and combat
@export var speed_bonus: float = 1.0 ## Speed multiplier, affects spore travel speed (future use)

# Ownership (-1 = neutral, 0 = player, 1 = AI)
var owner_id: int = -1:
	set(value):
		owner_id = value
		_update_visual_state()

# Current spore count
var current_spores: int = 0:
	set(value):
		current_spores = clamp(value, 0, int(max_energy * 2))
		_update_spore_label()

# Visual properties
var radius: float = 50.0:
	set(value):
		radius = value
		_update_collision_shape()
		_update_sprite_scale()

# Production
var production_rate: float = 1.0  # Base: 1 spore per second
var production_accumulator: float = 0.0

# Trees
var trees: Array[PlantedTree] = []
var tree_container: Node2D = null  # Created dynamically when first tree is planted

# Node references (assigned in _ready)
@onready var sprite: Sprite2D = $Sprite2D
@onready var collision_shape: CollisionShape2D = $CollisionShape2D
@onready var spore_label: Label = $SporeLabel
@onready var selection_indicator: Sprite2D = $SelectionIndicator

# Signals
signal spores_changed(new_count: int)
signal owner_changed(new_owner: int)
signal clicked(asteroid: Asteroid)


func _ready() -> void:
	# Enable input detection
	input_pickable = true
	input_event.connect(_on_input_event)

	# Initialize visual state
	_update_visual_state()
	_update_collision_shape()
	_update_sprite_scale()
	_update_spore_label()

	# Hide selection indicator by default
	if selection_indicator:
		selection_indicator.visible = false


func _process(delta: float) -> void:
	# Only owned asteroids produce spores
	if owner_id >= 0:
		produce_spores(delta)
		_update_tree_growth(delta)


## Produce spores over time based on asteroid stats
func produce_spores(delta: float) -> void:
	var base_rate = production_rate
	var energy_multiplier = max_energy / 100.0
	var defense_multiplier = defense_bonus
	var tree_multiplier = get_production_multiplier()

	production_accumulator += base_rate * energy_multiplier * defense_multiplier * tree_multiplier * delta

	# Convert accumulator to whole spores
	if production_accumulator >= 1.0:
		var new_spores = int(production_accumulator)
		current_spores += new_spores
		production_accumulator -= new_spores
		spores_changed.emit(current_spores)


## Set asteroid ownership and update visuals
func change_owner(new_owner: int) -> void:
	if owner_id != new_owner:
		# Destroy trees when ownership changes
		_clear_all_trees()

		owner_id = new_owner
		owner_changed.emit(new_owner)


## Get stat multipliers for calculations
func get_stat_multipliers() -> Dictionary:
	return {
		"energy": max_energy / 100.0,
		"defense": defense_bonus,
		"speed": speed_bonus
	}


## Show selection indicator
func select() -> void:
	if selection_indicator:
		selection_indicator.visible = true


## Hide selection indicator
func deselect() -> void:
	if selection_indicator:
		selection_indicator.visible = false


## Serialize asteroid state to dictionary for saving/networking
func to_dict() -> Dictionary:
	var tree_data = []
	for tree in trees:
		tree_data.append(tree.to_dict())

	return {
		"position": {"x": position.x, "y": position.y},
		"owner_id": owner_id,
		"current_spores": current_spores,
		"max_energy": max_energy,
		"defense_bonus": defense_bonus,
		"speed_bonus": speed_bonus,
		"radius": radius,
		"trees": tree_data
	}


## Restore asteroid state from dictionary
func from_dict(data: Dictionary) -> void:
	position = Vector2(data.position.x, data.position.y)
	owner_id = data.owner_id
	current_spores = data.current_spores
	max_energy = data.max_energy
	defense_bonus = data.defense_bonus
	speed_bonus = data.speed_bonus
	radius = data.radius

	# Restore trees
	if data.has("trees"):
		for tree_data in data.trees:
			var tree = PlantedTree.new()
			tree.restore_from_dict(tree_data)
			trees.append(tree)
			_spawn_tree_visual(tree)


## Update sprite based on ownership
func _update_visual_state() -> void:
	if not sprite:
		return

	# Load appropriate sprite based on ownership
	match owner_id:
		-1:  # Neutral
			sprite.modulate = Color(0.29, 0.33, 0.41)  # Gray
		0:   # Player
			sprite.modulate = Color(0.09, 0.77, 1.0)   # Cyan
		1:   # AI
			sprite.modulate = Color(0.97, 0.44, 0.44)  # Red


## Update collision shape size to match radius
func _update_collision_shape() -> void:
	if not collision_shape:
		return

	if not collision_shape.shape:
		collision_shape.shape = CircleShape2D.new()

	if collision_shape.shape is CircleShape2D:
		collision_shape.shape.radius = radius


## Update sprite scale to match radius (assumes 50px base sprite)
func _update_sprite_scale() -> void:
	if not sprite:
		return

	var base_size = 50.0  # Base radius in pixels
	var scale_factor = radius / base_size
	sprite.scale = Vector2(scale_factor, scale_factor)


## Update spore count label
func _update_spore_label() -> void:
	if not spore_label:
		return

	spore_label.text = str(current_spores)


## Handle mouse input on asteroid
func _on_input_event(_viewport: Node, event: InputEvent, _shape_idx: int) -> void:
	if event is InputEventMouseButton and event.pressed:
		clicked.emit(self)


## ===== Tree System Methods =====

## Get maximum trees allowed based on energy
func get_max_trees() -> int:
	return int(max_energy / 50.0)


## Check if tree can be planted
func can_plant_tree() -> bool:
	return owner_id == 0 and current_spores >= 20 and trees.size() < get_max_trees()


## Plant a tree of given type
func plant_tree(type: int) -> bool:
	if not can_plant_tree():
		return false

	current_spores -= 20
	var tree = PlantedTree.new()
	tree.tree_type = type
	tree.position_offset = _get_tree_position(trees.size())
	trees.append(tree)
	_spawn_tree_visual(tree)
	return true


## Calculate tree position around asteroid
func _get_tree_position(tree_index: int) -> Vector2:
	var max_trees = get_max_trees()
	if max_trees == 0:
		return Vector2.ZERO
	var angle = (TAU / max(max_trees, 1)) * tree_index
	var distance = radius + 30.0
	return Vector2(cos(angle), sin(angle)) * distance


## Get production multiplier from trees
func get_production_multiplier() -> float:
	var multiplier = 1.0
	for tree in trees:
		if tree.tree_type == 0:  # PRODUCTION
			multiplier += tree.get_bonus_value()
	return multiplier


## Get effective defense with tree bonuses
func get_effective_defense() -> float:
	var total = defense_bonus
	for tree in trees:
		if tree.tree_type == 1:  # DEFENSE
			total += tree.get_bonus_value()
	return total


## Get speed multiplier from trees
func get_speed_multiplier() -> float:
	var multiplier = speed_bonus
	for tree in trees:
		if tree.tree_type == 2:  # SPEED
			multiplier += tree.get_bonus_value()
	return multiplier


## Update tree growth each frame
func _update_tree_growth(delta: float) -> void:
	for tree in trees:
		if tree.update_growth(delta):
			_update_tree_visual(tree)


## Spawn visual representation of tree
func _spawn_tree_visual(tree: PlantedTree) -> void:
	if not tree_container:
		tree_container = Node2D.new()
		tree_container.name = "TreeContainer"
		add_child(tree_container)

	var visual = Sprite2D.new()
	visual.name = "Tree_%d" % trees.find(tree)
	visual.position = tree.position_offset
	visual.texture = _get_tree_texture(tree)
	visual.modulate = _get_owner_color()
	tree_container.add_child(visual)


## Update tree visual when growth stage changes
func _update_tree_visual(tree: PlantedTree) -> void:
	if not tree_container:
		return

	var index = trees.find(tree)
	if index == -1:
		return

	var visual = tree_container.get_node_or_null("Tree_%d" % index)
	if visual and visual is Sprite2D:
		visual.texture = _get_tree_texture(tree)


## Get texture path for tree
func _get_tree_texture(tree: PlantedTree) -> Texture2D:
	var type_name = ""
	match tree.tree_type:
		0:  # PRODUCTION
			type_name = "production"
		1:  # DEFENSE
			type_name = "defense"
		2:  # SPEED
			type_name = "speed"

	var path = "res://assets/sprites/trees/tree_%s_stage%d.svg" % [type_name, tree.growth_stage]
	return load(path)


## Get owner color for tree tinting
func _get_owner_color() -> Color:
	match owner_id:
		0:  # Player
			return Color(0.09, 0.77, 1.0)  # Cyan
		1:  # AI
			return Color(0.97, 0.44, 0.44)  # Red
		_:
			return Color(0.5, 0.5, 0.5)  # Gray


## Clear all tree visuals
func _clear_all_trees() -> void:
	trees.clear()
	if tree_container:
		tree_container.queue_free()
		tree_container = null
