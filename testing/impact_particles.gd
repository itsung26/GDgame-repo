extends GPUParticles3D

func setup(location_pos:Vector3, look_at_pos:Vector3):
	global_position = location_pos
	look_at(look_at_pos)
