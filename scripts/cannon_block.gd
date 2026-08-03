extends Block
class_name CannonBlock

enum CannonState {
	BASE,
	AIMING,
	FIRE
}

var cannon_state: CannonState = CannonState.BASE

func _ready() -> void:
	super._ready()

func on_tower_updated(new_index: int) -> void:
	if new_index > block_index:
		match cannon_state:
			CannonState.BASE:
				print("aim")
				cannon_state = CannonState.AIMING
				#if has_node("button_animation"):
					#$button_animation.visible = true
					#$button_animation.play("aim")
					#$button_animation.animation_finished.connect(func():
						#cannon_state = CannonState.FIRE
						#$Sprite2D.texture = load("res://assets/cannonblock/frames/cannon_tansform.tres")
						#$button_animation.visible = false
				Events.all_animation_finished.emit()
					#end, CONNECT_ONE_SHOT)
			CannonState.AIMING:
				print("fire")
				cannon_state = CannonState.FIRE
				#$Sprite2D.texture = load("res://assets/cannonblock/frames/cannon_tansform.tres")
				Events.all_animation_finished.emit()
			CannonState.FIRE:
				# already fired, no transition
				Events.all_animation_finished.emit()
				
	Events.all_animation_finished.emit()
