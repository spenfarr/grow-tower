extends Node2D

@onready var tower_container: Node2D = $TowerContainer
@onready var tower_manager: TowerManager = $TowerManager
@onready var red_button: Button = $UI/Buttons/RedButton
@onready var cannon_button: Button = $UI/Buttons/CannonButton
@onready var brick_button: Button = $UI/Buttons/BrickButton
@onready var ground_button: Button = $UI/Buttons/GroundButton
@onready var reset_button: Button = $UI/ResetButton
@onready var camera: Camera2D = $Camera2D
@onready var background: ColorRect = $Background
@onready var ground: ColorRect = $Ground
@onready var ruler: Ruler = $Ruler
@onready var win_label: Label = $UI/WinLabel
@onready var lose_label: Label = $UI/LoseLabel
@onready var events: Node = get_node("/root/Events")

var current_sequence: Array[String] = []
const MAX_SCROLLABLE_BLOCKS: int = 50
const SCROLL_STEP: float = 80.0
const WIN_HEIGHT_UNITS: float = 23.0
const LOSE_BLOCK_COUNT: int = 5
var camera_pan_y: float = 0.0
var game_won: bool = false
var game_lost: bool = false
var used_block_types: Array[String] = []

const BLOCK_DEFINITIONS: Array[Dictionary] = [
	{"name": "red_button", "growth": 1, "texture": "res://assets/buttonblock/frames/front.tres"},
	{"name": "cannon", "growth": 2, "texture": "res://assets/cannonblock/frames/cannon_base.tres"},
	{"name": "brick", "growth": 1, "texture": "res://assets/brickblock/frames/base_brick.tres"},
	{"name": "ground", "growth": 1, "texture": "res://assets/groundblock/frames/base_ground.tres"},
]

func _ready() -> void:
	red_button.pressed.connect(_on_block_button_pressed.bind("red_button"))
	cannon_button.pressed.connect(_on_block_button_pressed.bind("cannon"))
	brick_button.pressed.connect(_on_block_button_pressed.bind("brick"))
	ground_button.pressed.connect(_on_block_button_pressed.bind("ground"))
	reset_button.pressed.connect(_on_reset_button_pressed)
	events.all_animation_finished.connect(_on_all_animations_finished)
	camera.make_current()
	set_block_buttons_disabled(false)
	# Give the tower manager access to the container so it can reposition blocks
	tower_manager.tower_container = tower_container
	var standard_height = get_standard_block_height()
	background.offset_top = ground.offset_bottom - MAX_SCROLLABLE_BLOCKS * standard_height
	var ground_absolute_y = tower_container.position.y + tower_manager.ground_y
	ruler.configure(ground_absolute_y, standard_height, MAX_SCROLLABLE_BLOCKS)
	_update_camera_for_tower_height()

func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP:
			pan_camera(-SCROLL_STEP)
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			pan_camera(SCROLL_STEP)

func _on_block_button_pressed(block_name: String) -> void:
	# temp disabled for testing - each button only usable once
	if false:
		if block_name in used_block_types:
			return
		used_block_types.append(block_name)
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
	elif block_name == "cannon":
		block_scene = preload("res://scenes/cannon_block.tscn")
		block = block_scene.instantiate() as Block
	elif block_name == "brick":
		block_scene = preload("res://scenes/brick_block.tscn")
		block = block_scene.instantiate() as Block
	elif block_name == "ground":
		block_scene = preload("res://scenes/ground_block.tscn")
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

	# Every block already in the tower reacts to this new one landing above it.
	var reacting_blocks: Array[Block] = tower_manager.blocks.duplicate()
	tower_manager.add_block(block)
	current_sequence.append(block_name)
	_update_camera_for_tower_height()
	tower_manager.run_chain(reacting_blocks)

func _on_all_animations_finished() -> void:
	if check_win_condition():
		win_game()
	elif tower_manager.blocks.size() >= LOSE_BLOCK_COUNT && false: # && false is to allow testing
		lose_game()
	else:
		refresh_block_buttons()

func check_win_condition() -> bool:
	return tower_manager.stack_height / Block.STANDARD_BLOCK_HEIGHT >= WIN_HEIGHT_UNITS

func win_game() -> void:
	game_won = true
	win_label.visible = true
	set_block_buttons_disabled(true)

func lose_game() -> void:
	game_lost = true
	lose_label.visible = true
	set_block_buttons_disabled(true)

func _on_reset_button_pressed() -> void:
	reset_game()

func pan_camera(delta_y: float) -> void:
	var max_scroll_height = get_max_scroll_height()
	camera_pan_y = clamp(camera_pan_y + delta_y, -max_scroll_height, 0.0)
	camera.position.y = get_base_camera_y() + camera_pan_y

func _update_camera_for_tower_height() -> void:
	var viewport_height = max(1.0, get_viewport().size.y)
	var max_scroll_height = get_max_scroll_height()
	var needed_pan = -max(0.0, tower_manager.stack_height - viewport_height)
	camera_pan_y = clamp(needed_pan, -max_scroll_height, 0.0)
	camera.position.y = get_base_camera_y() + camera_pan_y

func get_base_camera_y() -> float:
	# Camera y at zero pan, so the ground rests at the bottom of the viewport.
	return ground.offset_bottom - max(1.0, get_viewport().size.y) / 2.0

func get_max_scroll_height() -> float:
	var standard_height = get_standard_block_height()
	return max(0.0, MAX_SCROLLABLE_BLOCKS * standard_height - get_viewport().size.y)

func get_standard_block_height() -> float:
	var sample_block = preload("res://scenes/block.tscn").instantiate() as Block
	sample_block.setup("sample", Color.WHITE, 1, "res://assets/buttonblock/frames/front.tres")
	var height = sample_block.get_visual_height()
	sample_block.queue_free()
	return height

func reset_game() -> void:
	for child in tower_container.get_children():
		child.queue_free()

	tower_manager.blocks.clear()
	tower_manager.interaction_pairs.clear()
	tower_manager.stack_height = 0.0
	current_sequence.clear()
	camera_pan_y = 0.0
	camera.position.y = get_base_camera_y()
	game_won = false
	game_lost = false
	used_block_types.clear()
	win_label.visible = false
	lose_label.visible = false
	set_block_buttons_disabled(false)

func set_block_buttons_disabled(disabled: bool) -> void:
	red_button.disabled = disabled
	cannon_button.disabled = disabled
	brick_button.disabled = disabled
	ground_button.disabled = disabled

func refresh_block_buttons() -> void:
	# Re-enable buttons after an animation chain, except ones already used
	# this game -- each block type can only be placed once.
	red_button.disabled = "red_button" in used_block_types
	cannon_button.disabled = "cannon" in used_block_types
	brick_button.disabled = "brick" in used_block_types
	ground_button.disabled = "ground" in used_block_types

func get_block_definition(block_name: String) -> Dictionary:
	for definition in BLOCK_DEFINITIONS:
		if definition["name"] == block_name:
			return definition
	return {}
