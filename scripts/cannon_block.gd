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
				cannon_state = CannonState.AIMING
				if animation:
					sprite.visible = false
					animation.visible = true
					animation.play("eat")
					animation.animation_finished.connect(func():
						cannon_state = CannonState.FIRE
						sprite.texture = load("res://assets/cannonblock/frames/cannon_guy.tres")
						animation.visible = false
						sprite.visible = true
						Events.all_animation_finished.emit()
					)
			CannonState.AIMING:
				cannon_state = CannonState.FIRE
				#$Sprite2D.texture = load("res://assets/cannonblock/frames/cannon_tansform.tres")
				Events.all_animation_finished.emit()
			CannonState.FIRE:
				# already fired, no transition
				Events.all_animation_finished.emit()
				
	Events.all_animation_finished.emit()
