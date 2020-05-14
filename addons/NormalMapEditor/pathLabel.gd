tool
extends Label

signal set_texture(texPath)

func can_drop_data(position, data):
	#var tex = data as Texture
	if !data is Dictionary || !data.has("type") || data["type"] != "files" || !data.has("files"):
		return false

	return load(data["files"][0]) is Texture

func drop_data(position, data):
	emit_signal("set_texture", data["files"][0])
	text = data["files"][0].get_basename()
