extends Block
class_name ButtonBlock

enum VisualState {
	FRONT,
	LEFT,
	RIGHT,
	EXTENDED
}

var visual_state: VisualState = VisualState.FRONT

func _ready() -> void:
	super._ready()

func on_tower_updated(new_index: int) -> void:
	if new_index > block_index:
		if has_node("buttonturningleft270"):
			visual_state = VisualState.LEFT
			$buttonturningleft270.visible = true
			$Sprite2D.visible = false
			$buttonturningleft270.play("turn_left")
			$buttonturningleft270.animation_finished.connect(
				func():
					visual_state = VisualState.EXTENDED
					$Sprite2D.texture = load("res://assets/buttonblock/frame3.tres")
					$Sprite2D.visible = true
					$buttonturningleft270.visible = false
			)
			
func _on_buttonturningleft_270_frame_changed() -> void:
	if $buttonturningleft270.frame >= 5: # 6th frame, 0-indexed
		$buttonturningleft270.flip_h = false
