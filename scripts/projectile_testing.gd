extends Level


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	super._ready()


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	super._process(delta)
	#Debug.log(EnemyPopulationHandler.getAllEnemies())
	#Debug.log(EnemyPopulationHandler.getClosestVisibleEnemy(player.global_position))
