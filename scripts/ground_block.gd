extends Block
class_name GroundBlock

const SWITCH_DELAY: float = 1.0
const POP_ANIMATION_DURATION: float = 0.3
const POP_START_SCALE: float = 0.05

var has_switched: bool = false

func _ready() -> void:
	super._ready()

func play_step() -> void:
	if has_switched:
		return
	has_switched = true

	await get_tree().create_timer(SWITCH_DELAY).timeout

	sprite.texture = load("res://assets/groundblock/frames/ground1.tres")
	# Reserve the new, taller footprint before animating in, same as
	# ButtonBlock's stage2 reveal, so neighbors above already have room.
	if tower_manager != null and block_index >= 0:
		tower_manager.notify_block_height_changed(block_index)

	await _pop_into_ground1()

func _pop_into_ground1() -> void:
	var texture_height: float = sprite.texture.get_size().y
	var target_scale_y: float = sprite.scale.y
	var reserved_bottom_y: float = get_visual_height() / 2.0

	_on_pop_step(POP_START_SCALE, texture_height, reserved_bottom_y)

	var tween := create_tween()
	tween.set_trans(Tween.TRANS_BACK)
	tween.set_ease(Tween.EASE_OUT)
	tween.tween_method(
		_on_pop_step.bind(texture_height, reserved_bottom_y),
		POP_START_SCALE,
		target_scale_y,
		POP_ANIMATION_DURATION
	)
	await tween.finished

func _on_pop_step(current_scale_y: float, texture_height: float, reserved_bottom_y: float) -> void:
	sprite.scale.y = current_scale_y
	var half_height: float = texture_height * current_scale_y / 2.0
	sprite.position.y = reserved_bottom_y - half_height
