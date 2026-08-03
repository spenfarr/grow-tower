extends Block
class_name ButtonBlock

enum ButtonState {
	FRONT,
	LEFT,
	RIGHT,
	EXTENDED
}

var button_state: ButtonState = ButtonState.FRONT

func _ready() -> void:
	super._ready()

func on_tower_updated(new_index: int) -> void:
	if new_index > block_index:
		if button_animation:
			match button_state:
				ButtonState.FRONT:
					button_animation.visible = true
					sprite.visible = false
					button_animation.play("turn_left_270")
					button_animation.animation_finished.connect(
						func():
							button_state = ButtonState.LEFT
							sprite.texture = load("res://assets/buttonblock/frames/left.tres")
							sprite.visible = true
							button_animation.visible = false
							Events.all_animation_finished.emit()
					)
				ButtonState.LEFT:
					button_animation.visible = true
					sprite.visible = false
					button_animation.play("turn_right")
					button_animation.animation_finished.connect(
						func():
							button_state = ButtonState.RIGHT
							sprite.texture = load("res://assets/buttonblock/frames/right.tres")
							
							sprite.visible = true
							button_animation.visible = false
							Events.all_animation_finished.emit()
					)
				ButtonState.RIGHT:
					sprite.texture = load("res://assets/buttonblock/frames/stage2.tres")
					button_state = ButtonState.EXTENDED
					sprite.offset = Vector2(-50,0)
					if tower_manager != null and block_index >= 0:
						tower_manager.notify_block_height_changed(block_index)
					Events.all_animation_finished.emit()
				_:
					print("Button Oopsy")
					Events.all_animation_finished.emit()
				
	if new_index == block_index:
		Events.all_animation_finished.emit()
			
