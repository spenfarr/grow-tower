extends Block
class_name BrickBlock

const WAKE_DURATION: float = 0.2
const SPLIT_PAUSE: float = 0.15
const ARMS_OUT_DURATION: float = 0.3
const HEAD_UP_DURATION: float = 0.3
const ARMS_TUCK_DURATION: float = 0.35
const HOLD_DURATION: float = 0.3
const ARMS_UNTUCK_DURATION: float = 0.3
const HEAD_DOWN_DURATION: float = 0.3
const ARMS_IN_DURATION: float = 0.25
const SETTLE_DURATION: float = 0.1

# Reconstructed "whole brick" layout, derived from how the atlas regions
# relate to base_brick's 276x271 reference frame, scaled by the 0.5 sprite
# scale used throughout the project.
const HEAD_REST_POS: Vector2 = Vector2(0, 41)
const LEFT_ARM_REST_POS: Vector2 = Vector2(-31.25, 0)
const RIGHT_ARM_REST_POS: Vector2 = Vector2(33.75, 0)

# Each arm sprite hangs off a pivot (LeftArmPivot/RightArmPivot in the scene)
# at this fixed local offset, so moving the pivot slides the arm without
# having to reposition the sprite itself. Pivot rest positions below are
# derived so that the arm still renders at *_ARM_REST_POS.
const LEFT_ARM_LOCAL_OFFSET: Vector2 = Vector2(-15, 55)
const RIGHT_ARM_LOCAL_OFFSET: Vector2 = Vector2(15, 55)
const LEFT_ARM_PIVOT_REST: Vector2 = LEFT_ARM_REST_POS - LEFT_ARM_LOCAL_OFFSET
const RIGHT_ARM_PIVOT_REST: Vector2 = RIGHT_ARM_REST_POS - RIGHT_ARM_LOCAL_OFFSET

# Estimated transformed-pose targets, in the same world (Block-local) space
# as *_ARM_REST_POS - these are a first guess and will likely need tuning
# once seen running in the editor.
const ARMS_OUT_OFFSET: Vector2 = Vector2(80, 0)
const HEAD_UP_OFFSET: Vector2 = Vector2(0, -100)
const LEFT_ARM_TUCK_POS: Vector2 = Vector2(-35, 70)
const RIGHT_ARM_TUCK_POS: Vector2 = Vector2(35, 70)

# Head sprite (98.5x53.5 at 0.5 scale) top edge flush with the block frame's
# (138x135.5 at 0.5 scale) top edge: -67.75 + 53.5/2 = -41.
const HEAD_DOWN_POS: Vector2 = Vector2(0, -41)

var has_transformed: bool = false
var is_transforming: bool = false

@onready var head_sprite: Sprite2D = $HeadSprite as Sprite2D
@onready var left_arm_pivot: Node2D = $LeftArmPivot as Node2D
@onready var right_arm_pivot: Node2D = $RightArmPivot as Node2D
@onready var left_arm_sprite: Sprite2D = $LeftArmPivot/LeftArmSprite as Sprite2D
@onready var right_arm_sprite: Sprite2D = $RightArmPivot/RightArmSprite as Sprite2D
@onready var left_connector: Sprite2D = $LeftConnector as Sprite2D
@onready var right_connector: Sprite2D = $RightConnector as Sprite2D

func _ready() -> void:
	super._ready()

func on_tower_updated(new_index: int) -> void:
	if new_index > block_index and not has_transformed:
		has_transformed = true
		_play_transform_sequence()
	elif new_index == block_index:
		Events.all_animation_finished.emit()

func _process(_delta: float) -> void:
	if is_transforming:
		_position_connector(left_connector, head_sprite.position, to_local(_arm_connector_point(left_arm_pivot, left_arm_sprite)))
		_position_connector(right_connector, head_sprite.position, to_local(_arm_connector_point(right_arm_pivot, right_arm_sprite)))

func _head_up_position() -> Vector2:
	return HEAD_REST_POS + HEAD_UP_OFFSET

func _play_transform_sequence() -> void:
	var head_up_pos: Vector2 = _head_up_position()
	var left_arm_out_pos: Vector2 = LEFT_ARM_REST_POS - ARMS_OUT_OFFSET
	var right_arm_out_pos: Vector2 = RIGHT_ARM_REST_POS + ARMS_OUT_OFFSET
	# Pivot targets are derived from the desired arm-sprite world position,
	# offset by the fixed local sprite offset. The arm no longer rotates (a
	# flip-frame swap sells the tuck instead), so both targets subtract the
	# same offset.
	var left_pivot_out: Vector2 = left_arm_out_pos - LEFT_ARM_LOCAL_OFFSET
	var right_pivot_out: Vector2 = right_arm_out_pos - RIGHT_ARM_LOCAL_OFFSET
	var left_pivot_tuck: Vector2 = LEFT_ARM_TUCK_POS - LEFT_ARM_LOCAL_OFFSET
	var right_pivot_tuck: Vector2 = RIGHT_ARM_TUCK_POS - RIGHT_ARM_LOCAL_OFFSET

	# Robot-arm textures are whatever's already on the sprites (set in the
	# scene); flip1/flip2 are the folding frames, reused mirrored for the
	# second half of the flip.
	var left_robot_tex: Texture2D = left_arm_sprite.texture
	var right_robot_tex: Texture2D = right_arm_sprite.texture
	var left_flip1_tex: Texture2D = load("res://assets/brickblock/frames/brick_arm_left_flip1.tres")
	var left_flip2_tex: Texture2D = load("res://assets/brickblock/frames/brick_arm_left_flip2.tres")
	var right_flip1_tex: Texture2D = load("res://assets/brickblock/frames/brick_arm_right_flip1.tres")
	var right_flip2_tex: Texture2D = load("res://assets/brickblock/frames/brick_arm_right_flip2.tres")

	var tween := create_tween()

	# Wake up: eyes open on the plain brick.
	tween.tween_callback(func(): sprite.texture = load("res://assets/brickblock/frames/brick_face.tres"))
	tween.tween_interval(WAKE_DURATION)

	# Split into head + two arm pieces, positioned to match the brick_face look.
	tween.tween_callback(_show_split_sprites)
	tween.tween_interval(SPLIT_PAUSE)

	# Connectors appear right as the arms start moving, and track the live
	# head/arm positions every frame from here until everything's back at rest.
	tween.tween_callback(_show_connectors)

	# Arms slide out to the sides (pivot translates, no rotation yet).
	tween.set_parallel(true)
	tween.tween_property(left_arm_pivot, "position", left_pivot_out, ARMS_OUT_DURATION).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tween.tween_property(right_arm_pivot, "position", right_pivot_out, ARMS_OUT_DURATION).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tween.set_parallel(false)

	# Head rises into place.
	tween.tween_property(head_sprite, "position", head_up_pos, HEAD_UP_DURATION).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

	# Arms swing their pivots into the tuck position while flipping through
	# frames (robot_arm -> flip1 -> flip2 -> flip2 mirrored -> robot_arm
	# mirrored) to sell flipping upside down and tucking under the head.
	tween.set_parallel(true)
	tween.tween_property(left_arm_pivot, "position", left_pivot_tuck, ARMS_TUCK_DURATION).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(right_arm_pivot, "position", right_pivot_tuck, ARMS_TUCK_DURATION).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	_queue_arm_flip(tween, left_arm_sprite, left_flip1_tex, left_flip2_tex, left_robot_tex, ARMS_TUCK_DURATION)
	_queue_arm_flip(tween, right_arm_sprite, right_flip1_tex, right_flip2_tex, right_robot_tex, ARMS_TUCK_DURATION)
	tween.set_parallel(false)

	# Hold the assembled robot pose briefly.
	tween.tween_interval(HOLD_DURATION)

	# Reverse: arms pull back out, staying on the flipped (mirrored robot_arm) frame.
	tween.set_parallel(true)
	tween.tween_property(left_arm_pivot, "position", left_pivot_out, ARMS_UNTUCK_DURATION).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(right_arm_pivot, "position", right_pivot_out, ARMS_UNTUCK_DURATION).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween.set_parallel(false)

	# Head lowers to rest flush with the top of the block frame.
	tween.tween_property(head_sprite, "position", HEAD_DOWN_POS, HEAD_DOWN_DURATION).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)

	# Arms slide back in to reform the plain brick silhouette.
	tween.set_parallel(true)
	tween.tween_property(left_arm_pivot, "position", LEFT_ARM_PIVOT_REST, ARMS_IN_DURATION)
	tween.tween_property(right_arm_pivot, "position", RIGHT_ARM_PIVOT_REST, ARMS_IN_DURATION)
	tween.set_parallel(false)
	tween.tween_callback(_hide_connectors)

	# Recombine into the single plain-brick sprite - disguise restored, but
	# flipped on its horizontal axis (top/bottom mirrored) from how it started.
	tween.tween_callback(_hide_split_sprites)
	tween.tween_interval(SETTLE_DURATION)
	tween.tween_callback(func(): sprite.texture = load("res://assets/brickblock/frames/base_brick.tres"))
	tween.tween_callback(func(): sprite.flip_v = true)
	tween.tween_callback(func(): Events.all_animation_finished.emit())

func _show_split_sprites() -> void:
	sprite.visible = false
	head_sprite.visible = true
	left_arm_sprite.visible = true
	right_arm_sprite.visible = true
	head_sprite.position = HEAD_REST_POS
	left_arm_pivot.position = LEFT_ARM_PIVOT_REST
	right_arm_pivot.position = RIGHT_ARM_PIVOT_REST
	left_arm_pivot.rotation = 0.0
	right_arm_pivot.rotation = 0.0

func _hide_split_sprites() -> void:
	head_sprite.visible = false
	left_arm_sprite.visible = false
	right_arm_sprite.visible = false
	sprite.texture = load("res://assets/brickblock/frames/brick_face_on_top.tres")
	sprite.visible = true

func _show_connectors() -> void:
	is_transforming = true
	_position_connector(left_connector, head_sprite.position, to_local(_arm_connector_point(left_arm_pivot, left_arm_sprite)))
	_position_connector(right_connector, head_sprite.position, to_local(_arm_connector_point(right_arm_pivot, right_arm_sprite)))
	left_connector.visible = true
	right_connector.visible = true

func _hide_connectors() -> void:
	is_transforming = false
	left_connector.visible = false
	right_connector.visible = false

func _position_connector(connector: Sprite2D, from_pos: Vector2, to_pos: Vector2) -> void:
	connector.position = (from_pos + to_pos) / 2.0
	connector.rotation = (to_pos - from_pos).angle()

# Fakes a 2D "page flip" instead of rotating the pivot: swap through
# robot_arm -> flip1 -> flip2 -> flip1 mirrored -> robot_arm mirrored,
# evenly spaced across duration. flip2 is the edge-on peak; the way back out
# re-shows flip1 then robot_arm flipped vertically (top/bottom mirrored, the
# arm swings over a horizontal hinge) so it reads as opening back up on its
# other side.
func _queue_arm_flip(tween: Tween, arm_sprite: Sprite2D, flip1_tex: Texture2D, flip2_tex: Texture2D, robot_tex: Texture2D, duration: float) -> void:
	var step: float = duration / 4.0
	tween.tween_callback(func(): arm_sprite.texture = flip1_tex).set_delay(step)
	tween.tween_callback(func(): arm_sprite.texture = flip2_tex).set_delay(step * 2)
	tween.tween_callback(func(): arm_sprite.texture = flip1_tex).set_delay(step * 3)
	tween.tween_callback(func(): arm_sprite.flip_v = true).set_delay(step * 3)
	tween.tween_callback(func(): arm_sprite.texture = robot_tex).set_delay(step * 4)
	tween.tween_callback(func(): arm_sprite.flip_v = true).set_delay(step * 4)

# The arm sprite's bottom edge is the skinny end of the L-shaped arm/leg
# art. Deriving it from the pivot (rather than the sprite's live
# global_position, which is its center) and re-reading texture size each
# call means the connector tracks that specific point even as the flip
# frames swap in textures of different heights.
func _arm_connector_point(pivot: Node2D, arm_sprite: Sprite2D) -> Vector2:
	var half_height: float = arm_sprite.texture.get_size().y * arm_sprite.scale.y / 2.0
	var local_bottom: Vector2 = arm_sprite.position + Vector2(0, half_height)
	return pivot.to_global(local_bottom)
