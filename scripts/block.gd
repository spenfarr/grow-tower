extends Area2D
class_name Block

signal interacted(with_block: Block)

const STANDARD_BLOCK_HEIGHT: float = 132.0
const ROUND_UP_TOLERANCE: float = 20.0

@export var block_name: String = "Block"
@export var block_color: Color = Color.WHITE
@export var growth_amount: int = 1
@export var texture_path: String = "res://assets/buttonblock/frame1.tres"

@onready var animation: AnimatedSprite2D = $AnimatedSprite2D as AnimatedSprite2D
@onready var sprite: Sprite2D = $Sprite2D as Sprite2D

var id: int = 0
var is_active: bool = false
var neighbors: Array[Block] = []
var tower_manager: TowerManager
var block_index: int = -1

func _ready() -> void:
	update_visuals()
	area_entered.connect(_on_area_entered)

	#var tower_manager: TowerManager = %TowerManager as TowerManager
	if tower_manager:
		tower_manager.tower_updated.connect(_on_tower_updated)

func setup(name_value: String, color_value: Color, growth_value: int = 1, texture_value: String = "res://assets/buttonblock/frame1.tres") -> void:
	block_name = name_value
	block_color = color_value
	growth_amount = growth_value
	texture_path = texture_value
	update_visuals()

	if tower_manager != null:
		block_index = tower_manager.blocks.size()

func trigger_interaction(other_block: Block) -> void:
	if other_block == null or other_block == self:
		return

	if other_block in neighbors:
		return

	neighbors.append(other_block)
	emit_signal("interacted", other_block)
	apply_growth()

func apply_growth() -> void:
	is_active = true
	if $AnimationPlayer.has_animation("grow"):
		$AnimationPlayer.play("grow")

func update_visuals() -> void:
	if has_node("Sprite2D"):
		$Sprite2D.modulate = block_color
		if ResourceLoader.exists(texture_path):
			$Sprite2D.texture = load(texture_path)

func get_visual_height() -> float:
	if has_node("Sprite2D"):
		var sprite: Sprite2D = $Sprite2D
		if sprite.texture != null:
			return quantize_height(sprite.texture.get_size().y * sprite.scale.y)
	return 32.0

func quantize_height(raw_height: float) -> float:
	# Round up to the next unit if within ROUND_UP_TOLERANCE px of it.
	return floor((raw_height + ROUND_UP_TOLERANCE) / STANDARD_BLOCK_HEIGHT) * STANDARD_BLOCK_HEIGHT

func _on_area_entered(area: Area2D) -> void:
	if area is Block and area != self:
		trigger_interaction(area as Block)

func _on_tower_updated(new_index: int) -> void:
	on_tower_updated(new_index)

func on_tower_updated(new_index: int) -> void:
	# Override in subclasses for per-block reaction to tower updates.
	pass
