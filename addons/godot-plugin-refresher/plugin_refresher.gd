tool
extends HBoxContainer

signal request_refresh_plugin(p_name)
signal request_enable_plugin(p_name)
#warning-ignore:unused_signal
signal request_disable_plugin(p_name)
signal plugin_changed(p_name)

var cur_plugin := ""
var enabled := false

onready var checkbox: CheckBox = $CheckBox
onready var options: OptionButton = $OptionButton
onready var refresh: Button = $RefreshButton
onready var confirm: ConfirmationDialog = $ConfirmationDialog


func _ready() -> void:
	# var _cur_scene = get_tree().edited_scene_root
	# assert(_cur_scene != self, "Scene: '%s' is opened in editor!" % _cur_scene)
	assert(OK == checkbox.connect("toggled", self, "_on_checkbox_toggled"))
	assert(OK == options.connect("item_selected", self, "_on_options_item_selected"))
	assert(OK == refresh.connect("pressed", self, "_on_refresh_button_pressed"))
	assert(OK == confirm.connect("confirmed", self, "_on_conf_dialog_confirmed"))
	refresh.icon = get_icon("Reload", "EditorIcons")

func update_items(_plugins: Dictionary) -> void:
	if not options:
		return
	options.clear()
	var _dirs: Array = _plugins.keys()
	for i in _dirs.size():
		var _dirname: String = _dirs[i]
		options.add_item(_plugins[_dirname], i)
		options.set_item_metadata(i, _dirname)
	if cur_plugin.empty():
		if not options.get_item_count():
			return
		cur_plugin = options.get_item_metadata(0)
		emit_signal("plugin_changed", cur_plugin)
		checkbox.pressed = enabled


func select_plugin(p_name: String) -> void:
	if not options or p_name.empty():
		return
	for i in options.get_item_count():
		cur_plugin = options.get_item_metadata(i)
		if cur_plugin == p_name:
			options.selected = options.get_item_id(i)
			emit_signal("plugin_changed", cur_plugin)
			checkbox.pressed = enabled
			break


func show_warning(_p_name: String) -> void:
	var _text: String = "Plugin '%s' is disabled.\n Do you want to enable it?" % _p_name
	confirm.dialog_text = _text
	confirm.popup_centered()


func _on_options_item_selected(_ind: int) -> void:
	cur_plugin = options.get_item_metadata(options.selected)
	emit_signal("plugin_changed", cur_plugin)
	checkbox.pressed = enabled


func _on_checkbox_toggled(_pressed: bool) -> void:
	if not options.get_item_count():
		checkbox.pressed = false
		return
	emit_signal("request_%s_plugin" % ("enable" if _pressed else "disable"), cur_plugin)


func _on_refresh_button_pressed() -> void:
	if not options.get_item_count():
		return
	emit_signal("request_refresh_plugin", cur_plugin)


func _on_conf_dialog_confirmed() -> void:
	emit_signal("request_enable_plugin", cur_plugin)
	checkbox.pressed = enabled
