extends EnviromentalHazard

enum sides {FRONT, BACK}


func _onHazardPlayerEnter(player:Player) -> void:
	var side_entered:sides
	if player.global_position.x >= global_position.x:
		side_entered = sides.BACK
	elif player.global_position.x < global_position.x:
		side_entered = sides.FRONT
	
	if side_entered == sides.FRONT:
		bounce_direction = -global_transform.basis.x.normalized()
	elif  side_entered == sides.BACK:
		bounce_direction = global_transform.basis.x.normalized()


func _onHazardEnemyEnter(enemy:Enemy) -> void:
	var side_entered: sides
	if enemy.global_position.x >= global_position.x:
		side_entered = sides.BACK
	elif enemy.global_position.x < global_position.x:
		side_entered = sides.FRONT

	if side_entered == sides.FRONT:
		bounce_direction = -global_transform.basis.x.normalized()
	elif side_entered == sides.BACK:
		bounce_direction = global_transform.basis.x.normalized()
