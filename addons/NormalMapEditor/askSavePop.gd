tool
extends ConfirmationDialog

enum { CHOOSED_CANCEL = 0, CHOOSED_OK, CHOOSED_DONT_SAVE }
var choosed


func _init():
	var dontSaveBtn = add_button("Don't Save", false, "dontSave")
	dontSaveBtn.connect("pressed", self, "on_dontSaveBtn_pressed")
	connect("confirmed", self, "on_confirmed")
	get_cancel().connect("pressed", self, "on_cancelBtn_pressed")

func on_dontSaveBtn_pressed():
	hide()
	choosed = CHOOSED_DONT_SAVE

func on_confirmed():
	choosed = CHOOSED_OK

func on_cancelBtn_pressed():
	choosed = CHOOSED_CANCEL
