extends Node2D

@onready var tower_container: Node2D = $TowerContainer
@onready var tower_manager: TowerManager = $TowerManager
@onready var red_button: Button = $UI/Buttons/RedButton
@onready var cannon_button: Button = $UI/Buttons/CannonButton
@onready var reset_button: Button = $UI/ResetButton
@onready var events: Node = get_node("/root/Events")

var current_sequence: Array[String] = []

const BLOCK_DEFINITIONS: Array[Dictionary] = [
	{"name": "red_button", "growth": 1, "texture": "res://assets/buttonblock/frames/front.tres"},
	{"name": "cannon", "growth": 2, "texture": "res://assets/cannonblock/frames/cannon_base.tres"},
]

func _ready() -> void:
	red_button.pressed.connect(_on_block_button_pressed.bind("red_button"))
	cannon_button.pressed.connect(_on_block_button_pressed.bind("cannon"))
	reset_button.pressed.connect(_on_reset_button_pressed)
	events.all_animation_finished.connect(_on_all_animations_finished)
	set_block_buttons_disabled(false)
	# Give the tower manager access to the container so it can reposition blocks
	tower_manager.tower_container = tower_container

func _on_block_button_pressed(block_name: String) -> void:
	if red_button.disabled or cannon_button.disabled:
		return
	spawn_block(block_name)

func spawn_block(block_name: String) -> void:
	var definition = get_block_definition(block_name)
	if definition.is_empty():
		return

	var block_scene: PackedScene
	var block: Block

	if block_name == "red_button":
		block_scene = preload("res://scenes/button_block.tscn")
		block = block_scene.instantiate() as Block
	else:
		block_scene = preload("res://scenes/block.tscn")
		block = block_scene.instantiate() as Block

	set_block_buttons_disabled(true)
	block.tower_manager = tower_manager
	block.setup(definition["name"], Color.WHITE, definition["growth"], definition["texture"])
	var block_height: float = block.get_visual_height()
	var new_y: float = tower_manager.get_next_spawn_y(block_height)
	block.position = Vector2(0, new_y)

	tower_container.add_child(block)

	tower_manager.add_block(block)
	current_sequence.append(block_name)

func _on_all_animations_finished() -> void:
	set_block_buttons_disabled(false)

func _on_reset_button_pressed() -> void:
	reset_game()

func reset_game() -> void:
	for child in tower_container.get_children():
		child.queue_free()

	tower_manager.blocks.clear()
	tower_manager.interaction_pairs.clear()
	tower_manager.stack_height = 0.0
	current_sequence.clear()
	set_block_buttons_disabled(false)

func set_block_buttons_disabled(disabled: bool) -> void:
	red_button.disabled = disabled
	cannon_button.disabled = disabled

func get_block_definition(block_name: String) -> Dictionary:
	for definition in BLOCK_DEFINITIONS:
		if definition["name"] == block_name:
			return definition
	return {}
