tool
extends HBoxContainer

signal request_refresh_plugin(plugin_name)
signal request_enable_plugin(plugin_name)
#warning-ignore:unused_signal
signal request_disable_plugin(plugin_name)
signal plugin_changed(plugin_name)

var cur_plugin := ""
var is_enabled := false

onready var checkbox: CheckBox = $CheckBox
onready var options_button: OptionButton = $OptionButton
onready var refresh_button: Button = $RefreshButton
onready var confirmation_dialog: ConfirmationDialog = $ConfirmationDialog


func _ready() -> void:
	assert(OK == checkbox.connect("toggled", self, "_on_checkbox_toggled"))
	assert(OK == options_button.connect("item_selected", self, "_on_options_item_selected"))
	assert(OK == refresh_button.connect("pressed", self, "_on_refresh_button_pressed"))
	assert(OK == confirmation_dialog.connect("confirmed", self, "_on_conf_dialog_confirmed"))
	refresh_button.icon = get_icon("Reload", "EditorIcons")


func update_items(plugins: Dictionary) -> void:
	if not options_button:
		return
	options_button.clear()
	var dirs: Array = plugins.keys()
	for i in dirs.size():
		var dir_name: String = dirs[i]
		options_button.add_item(plugins[dir_name], i)
		options_button.set_item_metadata(i, dir_name)
	if cur_plugin.empty():
		if not options_button.get_item_count():
			return
		cur_plugin = options_button.get_item_metadata(0)
		emit_signal("plugin_changed", cur_plugin)
		checkbox.pressed = is_enabled


func select_plugin(plugin_name: String) -> void:
	if not options_button or plugin_name.empty():
		return
	for i in options_button.get_item_count():
		cur_plugin = options_button.get_item_metadata(i)
		if cur_plugin == plugin_name:
			options_button.selected = options_button.get_item_id(i)
			emit_signal("plugin_changed", cur_plugin)
			checkbox.pressed = is_enabled
			break


func show_warning(plugin_name: String) -> void:
	var warning_message: String = "Plugin '%s' is disabled.\n Do you want to enable it?" % plugin_name
	confirmation_dialog.dialog_text = warning_message
	confirmation_dialog.popup_centered()


func _on_options_item_selected(id: int) -> void:
	cur_plugin = options_button.get_item_metadata(options_button.selected)
	emit_signal("plugin_changed", cur_plugin)
	checkbox.pressed = is_enabled


func _on_checkbox_toggled(pressed: bool) -> void:
	if not options_button.get_item_count():
		checkbox.pressed = false
		return
	emit_signal("request_%s_plugin" % ("enable" if pressed else "disable"), cur_plugin)


func _on_refresh_button_pressed() -> void:
	if not options_button.get_item_count():
		return
	emit_signal("request_refresh_plugin", cur_plugin)


func _on_conf_dialog_confirmed() -> void:
	emit_signal("request_enable_plugin", cur_plugin)
	checkbox.pressed = is_enabled
