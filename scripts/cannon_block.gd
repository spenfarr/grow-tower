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

func play_step() -> void:
	match cannon_state:
		CannonState.BASE:
			cannon_state = CannonState.AIMING
			if animation:
				sprite.visible = false
				animation.visible = true
				animation.play("eat")
				await animation.animation_finished
				cannon_state = CannonState.FIRE
				sprite.texture = load("res://assets/cannonblock/frames/cannon_guy.tres")
				animation.visible = false
				sprite.visible = true
		CannonState.AIMING:
			cannon_state = CannonState.FIRE
			#$Sprite2D.texture = load("res://assets/cannonblock/frames/cannon_tansform.tres")
		CannonState.FIRE:
			# already fired, no transition
			pass
