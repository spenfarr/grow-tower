extends Block
class_name ButtonBlock

enum ButtonState {
	FRONT,
	LEFT,
	RIGHT,
	EXTENDED
}

var button_state: ButtonState = ButtonState.FRONT

const GROW_ANIMATION_DURATION: float = 0.35
const GROW_START_SCALE: float = 0.05

@onready var top_sprite: Sprite2D = $TopSprite as Sprite2D

func _ready() -> void:
	super._ready()

func get_visual_height() -> float:
	var height: float = super.get_visual_height()
	# Use a direct lookup rather than the @onready top_sprite: this can be
	# called before the block enters the tree, when onready vars aren't set yet.
	if has_node("TopSprite"):
		var cap: Sprite2D = $TopSprite
		if cap.visible and cap.texture != null:
			height += quantize_height(cap.texture.get_size().y * cap.scale.y)
	return height

func play_step() -> void:
	if animation:
		match button_state:
			ButtonState.FRONT:
				animation.visible = true
				sprite.visible = false
				animation.play("turn_left_270")
				await animation.animation_finished
				button_state = ButtonState.LEFT
				sprite.texture = load("res://assets/buttonblock/frames/left.tres")
				sprite.visible = true
				animation.visible = false
			ButtonState.LEFT:
				animation.visible = true
				sprite.visible = false
				animation.play("turn_right")
				await animation.animation_finished
				button_state = ButtonState.RIGHT
				sprite.texture = load("res://assets/buttonblock/frames/right.tres")
				sprite.visible = true
				animation.visible = false
			ButtonState.RIGHT:
				sprite.texture = load("res://assets/buttonblock/frames/stage2.tres")
				button_state = ButtonState.EXTENDED
				sprite.offset = Vector2(-50,0)
				# Make the cap part of the block's footprint before recalculating
				# stack heights, so later blocks reserve space above it too.
				top_sprite.visible = true
				if tower_manager != null and block_index >= 0:
					tower_manager.notify_block_height_changed(block_index)
				await _grow_into_stage2()
			_:
				print("Button Oopsy")

func _grow_into_stage2() -> void:
	# Pop the grown sprite up from a squashed sliver to its full height, anchored
	# to the bottom edge so it reads as growing out of the block below rather
	# than expanding from its center. The cap rides along on top of the stem,
	# tracking its rising top edge each frame.
	#
	# Anchor to get_visual_height() / 2, not the stem's own raw half-height:
	# tower_manager centers this block's position around the full quantized
	# stem+cap height, so that's where the reserved slot's bottom actually is.
	var texture_height: float = sprite.texture.get_size().y
	var target_scale_y: float = sprite.scale.y
	var cap_half_height: float = top_sprite.texture.get_size().y * top_sprite.scale.y / 2.0
	var reserved_bottom_y: float = get_visual_height() / 2.0

	_on_grow_step(GROW_START_SCALE, texture_height, reserved_bottom_y, cap_half_height)

	var tween := create_tween()
	tween.set_trans(Tween.TRANS_BACK)
	tween.set_ease(Tween.EASE_OUT)
	tween.tween_method(
		_on_grow_step.bind(texture_height, reserved_bottom_y, cap_half_height),
		GROW_START_SCALE,
		target_scale_y,
		GROW_ANIMATION_DURATION
	)
	await tween.finished

func _on_grow_step(current_scale_y: float, texture_height: float, reserved_bottom_y: float, cap_half_height: float) -> void:
	sprite.scale.y = current_scale_y
	var stem_half_height: float = texture_height * current_scale_y / 2.0
	sprite.position.y = reserved_bottom_y - stem_half_height
	var stem_top_edge_y: float = sprite.position.y - stem_half_height
	top_sprite.position.y = stem_top_edge_y - cap_half_height
