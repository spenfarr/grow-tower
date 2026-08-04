extends Block
class_name CannonBlock

enum CannonState {
	BASE,
	AIMING,
	FIRE
}

@onready var arm_base: Sprite2D = $ArmBase as Sprite2D
@onready var arm: Line2D = $ArmBase/Arm as Line2D

var cannon_state: CannonState = CannonState.BASE

func _ready() -> void:
	super._ready()

func play_step() -> void:
	match cannon_state:
		CannonState.BASE:
			
			if animation:
				sprite.visible = false
				animation.visible = true
				animation.play("eat")
				await animation.animation_finished
				cannon_state = CannonState.AIMING
				sprite.texture = load("res://assets/cannonblock/frames/cannon_guy.tres")
				animation.visible = false
				sprite.visible = true
		CannonState.AIMING:
			cannon_state = CannonState.FIRE
			sprite.texture = load("res://assets/cannonblock/frames/cannon_base.tres")
			if arm:
				arm_base.visible = true
				await arm.play()
		CannonState.FIRE:
			# already fired, no transition
			pass
