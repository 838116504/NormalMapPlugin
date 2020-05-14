tool
extends HBoxContainer

signal item_name_changed(newName)
signal item_selected
signal item_visibity_changed(visible)

var item
var iconName

onready var nameEdit = $nameBg/nameEdit

func _ready():
	if iconName:
		$icon.texture = get_icon(iconName, "EditorIcons")
	if item:
		set_item_visible(item.get_visible())
	nameEdit.set_as_toplevel(true)

func select():
	$nameBg.select()

func unselect():
	$nameBg.unselect()

func set_item_visible(p_visible):
	if p_visible:
		$visible.texture_normal = get_icon("GuiVisibilityVisible", "EditorIcons")
	else:
		$visible.texture_normal = get_icon("GuiVisibilityHidden", "EditorIcons")

func get_item_name():
	return $nameBg/nameLabel.text

func set_item_name(p_name):
	$nameBg/nameLabel.text = p_name

func set_item_icon(p_icon):
	$icon.texture = p_icon

func _on_visible_pressed():
	if item:
		emit_signal("item_visibity_changed", !item.get_visible())
#		item.set_visible(!item.get_visible())
#		set_item_visible(item.get_visible())


func _on_nameBg_pressed():
	emit_signal("item_selected")


func _on_nameBg_right_pressed():
	nameEdit.text = $nameBg/nameLabel.text
	nameEdit.grab_focus()
	nameEdit.select_all()
	nameEdit.rect_position = $nameBg.get_global_rect().position
	nameEdit.rect_size = $nameBg.rect_size
	nameEdit.show_modal()


func _on_nameEdit_modal_closed():
	emit_signal("item_name_changed", nameEdit.text)


func _on_nameEdit_text_entered(new_text):
	nameEdit.hide()
	_on_nameEdit_modal_closed()
