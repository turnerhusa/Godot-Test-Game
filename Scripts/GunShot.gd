extends Sprite

# class member variables go here, for example:
# var a = 2
# var b = "textvar"

func _ready():
	get_node("Anim").play("Spawn")


func _on_Anim_animation_finished(anim_name):
	queue_free()
