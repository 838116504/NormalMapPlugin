tool
extends LineEdit

signal float_changed(newFloat)

func _ready():
# warning-ignore:return_value_discarded
	connect("text_changed", self, "_on_self_text_changed")
# warning-ignore:return_value_discarded
	connect("text_entered", self, "_on_self_text_entered")

func _on_self_text_changed(newText):
	var checkedText = String()
	var dotPos = -1
	var dotPos2 = -1
	var cPos = caret_position
	for i in range(newText.length()):
		match newText[i]:
			"1", "2", "3", "4", "5", "6", "7", "8", "9", "0":
				checkedText += newText[i]
			".":
				if dotPos == -1:
					dotPos = i
					dotPos2 = checkedText.length()
					checkedText += newText[i]
				elif (i >= cPos && i > dotPos) || (i < cPos && i < dotPos):
					checkedText.erase(dotPos2, 1)
					dotPos = i
					dotPos2 = checkedText.length()
					checkedText += newText[i]
			"-":
				if checkedText.length() == 0:
					checkedText += newText[i]
	
	if checkedText.length() == 0:
		checkedText = "0"
	
	var diff = newText.length() - checkedText.length()
	if diff > 0:
		text = checkedText
		caret_position = cPos - diff
	
	emit_signal("float_changed", text.to_float())

# warning-ignore:unused_argument
func _on_self_text_entered(newText):
	release_focus()
