extends Node
class_name TowerManager

var blocks: Array[Block] = []
var interaction_pairs: Array[Dictionary] = []
var ground_y: float = 440.0
var stack_height: float = 0.0
var tower_container: Node2D = null
var chain_queue: Array[Block] = []

func add_block(block: Block) -> void:
	if block == null:
		return

	blocks.append(block)
	stack_height += block.get_visual_height()

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

func get_max_height() -> int:
	return blocks.size()

func run_chain(chain: Array[Block]) -> void:
	# Plays each block's next animation step in order, waiting for one to
	# finish before starting the next. A block can appear more than once
	# (e.g. [a, c, b, a]) since each call just advances that block's own
	# internal state to whatever comes next. Blocks can call queue_next()
	# during their own play_step() to insert a block to run immediately
	# after them, ahead of whatever else is already queued.
	chain_queue = chain
	while not chain_queue.is_empty():
		var block: Block = chain_queue.pop_front()
		await block.play_step()
	Events.all_animation_finished.emit()

func queue_next(block: Block) -> void:
	chain_queue.push_front(block)
