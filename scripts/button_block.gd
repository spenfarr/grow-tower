extends Block
class_name ButtonBlock

enum VisualState {
	FRONT,
	LEFT,
	RIGHT,
	EXTENDED
}

var visual_state: VisualState = VisualState.FRONT

@onready var button_animation : AnimatedSprite2D = $ButtonAnimation as AnimatedSprite2D

func _ready() -> void:
	super._ready()

func on_tower_updated(new_index: int) -> void:
	if new_index > block_index:
		if button_animation:
			visual_state = VisualState.LEFT
			button_animation.visible = true
			$Sprite2D.visible = false
			button_animation.play("turn_left_270")
			button_animation.animation_finished.connect(
				func():
					visual_state = VisualState.EXTENDED
					$Sprite2D.texture = load("res://assets/buttonblock/left.tres")
					$Sprite2D.visible = true
					button_animation.visible = false
			)
