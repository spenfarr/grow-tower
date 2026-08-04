extends Line2D

signal hand_at_top   # fires each time the arm reaches the top, so callers can swap the hand's texture

@onready var hand: Sprite2D = $Hand as Sprite2D

@export var segment_count: int = 24
@export var length: float = 366.0
@export var bend_degrees: float = 180.0   # 180 = full U, base fixed, tip ends pointing left
@export var cycle_duration: float = 1.5
@export var hold_time: float = 0.2

func _ready():
	# Line2D ignores AtlasTexture's region and draws the whole source image,
	# so crop the region ourselves into a standalone texture instead.
	var atlas: AtlasTexture = preload("res://assets/cannonblock/frames/arm_no_hand.tres")
	var source_image: Image = atlas.atlas.get_image()
	var cropped_image: Image = source_image.get_region(Rect2i(atlas.region))

	width = cropped_image.get_height()
	length = cropped_image.get_width()
	texture = ImageTexture.create_from_image(cropped_image)
	texture_mode = Line2D.LINE_TEXTURE_STRETCH

	_apply_bend(0.0)

func play() -> void:
	# out -> top -> (hand texture may change) -> bottom -> top -> (hand
	# texture may change) -> out. Fixed sequence, not optional. Plays once.
	var tween = create_tween()

	_add_bend_phase(tween, 0.0, bend_degrees)
	tween.tween_callback(hand_at_top.emit)
	if hold_time > 0.0:
		tween.tween_interval(hold_time)

	_add_bend_phase(tween, bend_degrees, -bend_degrees)
	_add_bend_phase(tween, -bend_degrees, bend_degrees)
	tween.tween_callback(hand_at_top.emit)
	if hold_time > 0.0:
		tween.tween_interval(hold_time)

	_add_bend_phase(tween, bend_degrees, 0.0)
	await tween.finished

func _add_bend_phase(tween: Tween, from_degrees: float, to_degrees: float) -> void:
	tween.tween_method(_apply_bend, from_degrees, to_degrees, cycle_duration)\
		 .set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

func _apply_bend(signed_bend_degrees: float) -> void:
	# Sign only flips the curl direction (up vs. down); the arc shape itself
	# is built from the magnitude so "down" is a true vertical mirror of
	# "up" rather than the same curl reflected sideways.
	var direction: float = -1.0 if signed_bend_degrees < 0.0 else 1.0
	var theta: float = deg_to_rad(absf(signed_bend_degrees))
	# Clamp theta away from zero (not just the radius denominator) --
	# otherwise swept = theta * s is exactly 0 for every point when theta
	# hits 0.0, collapsing the whole line to a single point (invisible) each
	# time it settles back to rest instead of degenerating to a straight line.
	if theta < 0.001:
		theta = 0.001

	# Radius shrinks as theta grows so the arc length always equals `length`
	# -- tiny theta keeps radius huge, so the arc reads as a straight line.
	var radius: float = length / theta

	var new_points: Array[Vector2] = []
	for i in range(segment_count + 1):
		var s: float = float(i) / segment_count
		var swept: float = theta * s
		new_points.append(Vector2(radius * sin(swept), direction * -radius * (1.0 - cos(swept))))

	points = new_points
	_update_hand(new_points)

func _update_hand(current_points: Array[Vector2]) -> void:
	if hand == null or current_points.size() < 2:
		return
	var tip: Vector2 = current_points[current_points.size() - 1]
	var prev: Vector2 = current_points[current_points.size() - 2]
	hand.position = tip
	hand.rotation = (tip - prev).angle()
