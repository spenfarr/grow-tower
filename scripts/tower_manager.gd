extends Node
class_name TowerManager

signal tower_updated(new_index: int)

var blocks: Array[Block] = []
var interaction_pairs: Array[Dictionary] = []
var ground_y: float = 440.0
var stack_height: float = 0.0
var tower_container: Node2D = null

func add_block(block: Block) -> void:
	if block == null:
		return

	blocks.append(block)
	stack_height += block.get_visual_height()
	tower_updated.emit(blocks.size() - 1)

func get_next_spawn_y(block_height: float) -> float:
	return ground_y - (stack_height + block_height / 2.0)

func notify_block_height_changed(changed_index: int) -> void:
	# Recompute total stack height and reposition all blocks accordingly.
	stack_height = 0.0
	for b in blocks:
		stack_height += b.get_visual_height()

	var cumulative: float = 0.0
	for i in range(blocks.size()):
		var b: Block = blocks[i]
		var h: float = b.get_visual_height()
		var y: float = ground_y - (cumulative + h / 2.0)
		if b.get_parent() != null:
			b.position = Vector2(b.position.x, y)
		cumulative += h

func register_interaction(source: Block, target: Block) -> void:
	if source == null or target == null or source == target:
		return

	interaction_pairs.append({"source": source, "target": target})
	tower_updated.emit(blocks.size() - 1)

func get_max_height() -> int:
	return blocks.size()
