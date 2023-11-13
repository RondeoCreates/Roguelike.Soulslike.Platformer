extends StaticBody2D


# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass

func disable( disabled ):
	$"CollisionShape2D".disabled = disabled


func getX():
	print_debug(get_parent().position.x)
	return get_parent().position.x
