class_name PlantedTree
extends Resource

## Tree entity that can be planted on asteroids
##
## Trees provide stat bonuses when mature and grow through 4 stages over 30 seconds.
## Three tree types: Production (+50% generation), Defense (+50% defense), Speed (+30% speed)

enum TreeType { PRODUCTION, DEFENSE, SPEED }
enum GrowthStage { SAPLING = 0, YOUNG = 1, MATURE = 2, ANCIENT = 3 }

@export var tree_type: int = 0
@export var growth_stage: int = 0
@export var growth_timer: float = 0.0
@export var position_offset: Vector2 = Vector2.ZERO

const GROWTH_STAGE_DURATION = 7.5  # 30 seconds / 4 stages
const BONUS_VALUES = {
	TreeType.PRODUCTION: 0.5,  # +50% spore production
	TreeType.DEFENSE: 0.5,      # +50% defense bonus
	TreeType.SPEED: 0.3         # +30% spore travel speed
}


## Initialize tree with specific type
func setup(type: int) -> void:
	tree_type = type


## Update tree growth and return true if stage advanced
func update_growth(delta: float) -> bool:
	if growth_stage < GrowthStage.ANCIENT:
		growth_timer += delta
		if growth_timer >= GROWTH_STAGE_DURATION:
			growth_timer = 0.0
			growth_stage += 1
			return true  # Stage advanced
	return false


## Check if tree is mature (provides bonuses)
func is_mature() -> bool:
	return growth_stage >= GrowthStage.MATURE


## Get the bonus value this tree provides
func get_bonus_value() -> float:
	if is_mature():
		return BONUS_VALUES[tree_type]
	return 0.0


## Serialize tree state to dictionary
func to_dict() -> Dictionary:
	return {
		"type": tree_type,
		"stage": growth_stage,
		"timer": growth_timer,
		"offset": {"x": position_offset.x, "y": position_offset.y}
	}


## Restore tree state from dictionary
func restore_from_dict(data: Dictionary) -> void:
	tree_type = data.type
	growth_stage = data.stage
	growth_timer = data.timer
	position_offset = Vector2(data.offset.x, data.offset.y)
