extends Node2D

@onready var tower_container: Node2D = $TowerContainer
@onready var tower_manager: TowerManager = $TowerManager
@onready var red_button: Button = $UI/MarginContainer/Buttons/RedButton
@onready var cannon_button: Button = $UI/MarginContainer/Buttons/CannonButton

var current_sequence: Array[String] = []

const BLOCK_DEFINITIONS: Array[Dictionary] = [
	{"name": "red_button", "growth": 1, "texture": "res://assets/buttonblock/frame1.tres"},
	{"name": "cannon", "growth": 2, "texture": "res://assets/cannonblock/cannon_base.tres"},
]

func _ready() -> void:
	red_button.pressed.connect(_on_block_button_pressed.bind("red_button"))
	cannon_button.pressed.connect(_on_block_button_pressed.bind("cannon"))

func _on_block_button_pressed(block_name: String) -> void:
	spawn_block(block_name)

func spawn_block(block_name: String) -> void:
	var definition = get_block_definition(block_name)
	if definition.is_empty():
		return

	var block_scene: PackedScene = preload("res://scenes/block.tscn")
	var block: Block = block_scene.instantiate() as Block

	block.tower_manager = tower_manager	
	block.setup(definition["name"], Color.WHITE, definition["growth"], definition["texture"])
	var block_height: float = block.get_visual_height()
	var new_y: float = tower_manager.get_next_spawn_y(block_height)
	block.position = Vector2(0, new_y)
	
	tower_container.add_child(block)

	tower_manager.add_block(block)
	current_sequence.append(block_name)

func get_block_definition(block_name: String) -> Dictionary:
	for definition in BLOCK_DEFINITIONS:
		if definition["name"] == block_name:
			return definition
	return {}
