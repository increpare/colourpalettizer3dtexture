extends Node3D

@export var rotate_speed:float=1.0
func _process(delta):
	self.rotate(Vector3.UP,delta*rotate_speed)
