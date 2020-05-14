tool
extends Node

func set_param(p_texture, p_parms):
	$distanceView/img.texture = p_texture
	$normalView/img.texture = p_texture
	$distanceView/img.position = p_texture.get_size() / 2
	$normalView/img.position = p_texture.get_size() / 2
	$normalView.size = p_texture.get_size()
	$distanceView.size = p_texture.get_size()
	var paramName = [ "emboss_height", "bump_height", "blur", "bump", "with_distance", "with_emboss"]
	for i in paramName.size():
		$normalView/img.material.set_shader_param(paramName[i], p_parms[i])
		#print(paramName[i], " = ", str(p_parms[i]))
	$normalView/img.material.set_shader_param("distanceTex", $distanceView.get_texture())

	$distanceView.render_target_update_mode = Viewport.UPDATE_ONCE
	$normalView.render_target_update_mode = Viewport.UPDATE_ALWAYS

func get_texture() -> Texture:
	return $normalView.get_texture()
