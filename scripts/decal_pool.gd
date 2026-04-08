extends Node
## Autoload: generic [Decal] pooling keyed by [PackedScene]. Register scenes once (or pass them to [method request] to auto-register).
## Each pool tracks free + active arrays; returning decals is required for sustained reuse.

const META_POOL_SCENE:StringName = &"_decal_pool_scene"

## Default pool size when [method register_pool] is not used before the first [method request].
var default_max_per_pool:int = 1000
## PackedScene resource id -> bucket (avoids duplicating per-decal-type fields).
var _buckets:Dictionary = {}


## Creates or updates a pool bucket for a scene and pre-fills free decals.
func register_pool(scene:PackedScene, max_count:int) -> void:
	if scene == null:
		Debug.logerr("DecalPool.register_pool: scene is null.")
		return
	if _buckets.has(scene):
		var existing:PoolBucket = _buckets[scene] as PoolBucket
		if existing.max_count != max_count:
			existing.max_count = max_count
			_trim_free_to_max(existing)
		return
	var bucket:PoolBucket = PoolBucket.new()
	bucket.scene = scene
	bucket.max_count = max_count
	_buckets[scene] = bucket
	_warm_bucket(bucket)



## Gets a decal from free list, or recycles the oldest active decal when saturated.
func request(scene:PackedScene) -> Decal:
	if scene == null:
		Debug.logerr("DecalPool.request: scene is null.")
		return null
	assert(_buckets.has(scene), "DecalPool.request: scene was requested before register_pool(scene, max_count).")
	var bucket:PoolBucket = _buckets[scene] as PoolBucket
	var decal:Decal
	if not bucket.free_list.is_empty():
		# Fast path: reuse an already-instantiated decal.
		decal = bucket.free_list.pop_front() as Decal
	else:
		if bucket.active.is_empty():
			Debug.logerr("DecalPool.request: pool empty for scene (no free or active to reclaim).")
			return null
		# Saturated path: reclaim the oldest active decal.
		decal = bucket.active.pop_front() as Decal
		var p:Node = decal.get_parent()
		if p != null:
			p.remove_child(decal)
	bucket.active.append(decal)
	decal.set_meta(META_POOL_SCENE, scene)
	return decal



## Returns a decal to its originating pool.
## Call this when the decal lifetime/fade has finished.
func return_decal(decal:Decal) -> void:
	if decal == null or not is_instance_valid(decal):
		return
	if not decal.has_meta(META_POOL_SCENE):
		Debug.logerr("DecalPool.return_decal: decal was not acquired from this pool (missing meta).")
		return
	var scene:PackedScene = decal.get_meta(META_POOL_SCENE) as PackedScene
	decal.remove_meta(META_POOL_SCENE)
	if not _buckets.has(scene):
		Debug.logerr("DecalPool.return_decal: unknown pool scene.")
		decal.queue_free()
		return
	var bucket:PoolBucket = _buckets[scene] as PoolBucket
	bucket.active.erase(decal)
	if decal.get_parent() != null:
		decal.get_parent().remove_child(decal)
	bucket.free_list.append(decal)
	_trim_free_to_max(bucket)



## Frees every pooled decal instance and resets all buckets.
func clear_all_pools() -> void:
	for scene:Variant in _buckets.keys():
		var bucket:PoolBucket = _buckets[scene] as PoolBucket
		_free_bucket_nodes(bucket)
	_buckets.clear()



## Returns whether a scene has been registered as a pool key.
func is_pool_registered(scene:PackedScene) -> bool:
	if scene == null:
		return false
	return _buckets.has(scene)



## Returns pool stats for debug/profiling without exposing internal bucket objects.
func get_registered_pools() -> Array[Dictionary]:
	var pools:Array[Dictionary] = []
	for scene:Variant in _buckets.keys():
		var bucket:PoolBucket = _buckets[scene] as PoolBucket
		var free_count:int = bucket.free_list.size()
		var active_count:int = bucket.active.size()
		pools.append({
			"scene": scene,
			"max_count": bucket.max_count,
			"free_count": free_count,
			"active_count": active_count,
			"total_count": free_count + active_count
		})
	return pools



## Instantiates decals until free_list reaches max_count.
func _warm_bucket(bucket:PoolBucket) -> void:
	while bucket.free_list.size() < bucket.max_count:
		var node:Node = bucket.scene.instantiate()
		var decal:Decal = node as Decal
		if decal == null:
			Debug.logerr("DecalPool: pooled scene root must be a Decal.")
			node.queue_free()
			return
		bucket.free_list.append(decal)



## Enforces bucket cap by freeing oldest entries in free_list.
func _trim_free_to_max(bucket:PoolBucket) -> void:
	while bucket.free_list.size() > bucket.max_count:
		var oldest:Decal = bucket.free_list.pop_front() as Decal
		if is_instance_valid(oldest):
			oldest.queue_free()


## Internal hard cleanup used by [method clear_all_pools].
func _free_bucket_nodes(bucket:PoolBucket) -> void:
	for d:Variant in bucket.free_list:
		var decal:Decal = d as Decal
		if is_instance_valid(decal):
			decal.queue_free()
	bucket.free_list.clear()
	for d:Variant in bucket.active:
		var decal:Decal = d as Decal
		if is_instance_valid(decal):
			decal.queue_free()
	bucket.active.clear()


#func _process(delta: float) -> void:
	#Debug.log(_buckets)

## Internal: one scene, two queues, one cap.
class PoolBucket:
	var scene:PackedScene
	var max_count:int = 1000
	var free_list:Array[Decal] = []
	var active:Array[Decal] = []
