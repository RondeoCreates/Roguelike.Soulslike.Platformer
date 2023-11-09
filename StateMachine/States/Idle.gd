extends State


func enter(_msg := {}) -> void:
	owner.velocity = Vector2.ZERO

func update(delta: float) -> void:
	if not owner.is_on_floor():
		state_machine.transition_to( "Fall" )
		return
	
	if Input.is_action_just_released()
