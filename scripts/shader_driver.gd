@tool
class_name ShaderDriver
extends Node
## Utility node that exposes a public API allowing easy modifying of shader parameters
## on a target mesh material.

## Target mesh instance containing the shader material to drive.
@export var mesh_node:MeshInstance3D:
	set = setMeshNode
## When true, [member surface_material_index] is ignored and [member MeshInstance3D.material_override] is used.
@export var use_material_override:bool = false
## Surface material index used when [member use_material_override] is false.
@export var surface_material_index:int = 0

var _shader_material:ShaderMaterial


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	_cacheShaderMaterialReference()


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if _shader_material == null:
		_cacheShaderMaterialReference()


## Sets a shader uniform value on the currently resolved shader material.
func setShaderParameter(param:StringName, value:Variant) -> void:
	if mesh_node == null:
		Debug.log("No mesh node found!")
		return
	
	if _shader_material == null:
		_cacheShaderMaterialReference()
	
	if _shader_material == null:
		return

	var shader:Shader = _shader_material.shader
	if shader != null:
		var has_uniform:bool = false
		var uniform_list:Array = shader.get_shader_uniform_list()
		for uniform_data_untyped:Variant in uniform_list:
			var uniform_data:Dictionary = uniform_data_untyped
			if StringName(uniform_data.get("name", "")) == param:
				has_uniform = true
				break
		if not has_uniform:
			Debug.logwarn(
				"ShaderDriver: uniform '" + String(param) + "' was not found on shader '" + shader.resource_path + "'."
			)
			return
	
	_shader_material.set_shader_parameter(param, value)


## Gets a shader uniform value from the currently resolved shader material.
func getShaderParameter(param:StringName) -> Variant:
	if mesh_node == null:
		Debug.log("No mesh node found!")
		return
	
	if _shader_material == null:
		_cacheShaderMaterialReference()
	
	if _shader_material == null:
		return null
	
	return _shader_material.get_shader_parameter(param)


## Forces the material cache to refresh from the current exported settings.
func refresh() -> void:
	_cacheShaderMaterialReference()


## Setter for [member mesh_node]. Re-caches shader material immediately.
func setMeshNode(new_mesh_node:MeshInstance3D) -> void:
	mesh_node = new_mesh_node
	_cacheShaderMaterialReference()


func _cacheShaderMaterialReference() -> void:
	_shader_material = null
	if mesh_node == null:
		return
	
	var material:Material
	if use_material_override:
		material = mesh_node.material_override
	else:
		material = mesh_node.get_active_material(surface_material_index)
	
	if material is ShaderMaterial:
		_shader_material = material
