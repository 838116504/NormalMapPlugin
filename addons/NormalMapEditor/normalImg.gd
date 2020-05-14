tool
extends Sprite

func _init():
	material = ShaderMaterial.new()
	material.shader = preload("normalmap.shader")
