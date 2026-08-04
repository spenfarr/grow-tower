extends Node2D

@onready var tower_container: Node2D = $TowerContainer
@onready var tower_manager: TowerManager = $TowerManager
@onready var red_button: Button = $UI/Buttons/RedButton
@onready var cannon_button: Button = $UI/Buttons/CannonButton
@onready var brick_button: Button = $UI/Buttons/BrickButton
@onready var reset_button: Button = $UI/ResetButton
@onready var camera: Camera2D = $Camera2D
@onready var background: ColorRect = $Background
@onready var ground: ColorRect = $Ground
@onready var ruler: Ruler = $Ruler
@onready var events: Node = get_node("/root/Events")

var current_sequence: Array[String] = []
const MAX_SCROLLABLE_BLOCKS: int = 50
const SCROLL_STEP: float = 80.0
var camera_pan_y: float = 0.0

const BLOCK_DEFINITIONS: Array[Dictionary] = [
	{"name": "red_button", "growth": 1, "texture": "res://assets/buttonblock/frames/front.tres"},
	{"name": "cannon", "growth": 2, "texture": "res://assets/cannonblock/frames/cannon_base.tres"},
	{"name": "brick", "growth": 1, "texture": "res://assets/brickblock/frames/base_brick.tres"},
]

func _ready() -> void:
	red_button.pressed.connect(_on_block_button_pressed.bind("red_button"))
	cannon_button.pressed.connect(_on_block_button_pressed.bind("cannon"))
	brick_button.pressed.connect(_on_block_button_pressed.bind("brick"))
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
	if red_button.disabled or cannon_button.disabled or brick_button.disabled:
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
	elif block_name == "cannon":
		block_scene = preload("res://scenes/cannon_block.tscn")
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
	_update_camera_for_tower_height()

func _on_all_animations_finished() -> void:
	set_block_buttons_disabled(false)

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
	set_block_buttons_disabled(false)

func set_block_buttons_disabled(disabled: bool) -> void:
	red_button.disabled = disabled
	cannon_button.disabled = disabled
	brick_button.disabled = disabled

func get_block_definition(block_name: String) -> Dictionary:
	for definition in BLOCK_DEFINITIONS:
		if definition["name"] == block_name:
			return definition
	return {}
