extends Node
class_name TowerManager

signal tower_updated

var blocks: Array[Block] = []
var interaction_pairs: Array[Dictionary] = []
var ground_y: float = 440.0
var stack_height: float = 0.0

func add_block(block: Block) -> void:
    if block == null:
        return

    blocks.append(block)
    stack_height += block.get_visual_height()
    tower_updated.emit()

func get_next_spawn_y(block_height: float) -> float:
    return ground_y - (stack_height + block_height / 2.0)

func register_interaction(source: Block, target: Block) -> void:
    if source == null or target == null or source == target:
        return

    interaction_pairs.append({"source": source, "target": target})
    tower_updated.emit()

func get_max_height() -> int:
    return blocks.size()
