class_name PistolBombShotCollsionReciever
extends StaticBody3D


## Returns the [PistolBomb] owning this collision reciever
func getPistolBomb() -> PistolBomb:
	var ret:PistolBomb = get_parent()
	return ret
