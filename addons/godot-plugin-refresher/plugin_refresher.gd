tool
extends HBoxContainer

signal request_refresh_plugin(p_name)
signal request_enable_plugin(p_name)
#warning-ignore:unused_signal
signal request_disable_plugin(p_name)
signal plugin_changed(p_name)

var cur_plugin := ""
var enabled := false

onready var checkbox = $CheckBox as CheckBox
onready var options = $OptionButton as OptionButton
onready var refresh = $RefreshButton as Button

var refresh_icon : Texture
var menu_icon : Texture

func _ready() -> void:
	var _cur_scene = get_tree().edited_scene_root
	assert(_cur_scene != self, "Scene: '%s' is opened in editor!" % _cur_scene)
	$MenuButton.icon = menu_icon
	refresh.icon = refresh_icon
	assert(OK == checkbox.connect("toggled", self, "_on_CheckBox_toggled"))
	assert(OK == options.connect("item_selected", self, "_on_OptionsItem_selected"))
	assert(OK == refresh.connect("pressed", self, "_on_RefreshButton_pressed"))
	assert(OK == $ConfirmationDialog.connect("confirmed", self, "_on_ConfirmationDialog_confirmed"))

func update_items(_plugins : Dictionary) -> void:
	if !options:
		return
	options.clear()
	var _dirs = _plugins.keys()
	for i in _dirs.size():
		var _dirname = _dirs[i]
		options.add_item(_plugins[_dirname], i)
		options.set_item_metadata(i, _dirname)
	if cur_plugin.empty():
		if options.get_item_count() == 0:
			return
		cur_plugin = options.get_item_metadata(0)
		emit_signal("plugin_changed", cur_plugin)
		checkbox.pressed = enabled

func select_plugin(p_name : String) -> void:
	if !options or p_name.empty():
		return
	for i in options.get_item_count():
		cur_plugin = options.get_item_metadata(i)
		if cur_plugin == p_name:
			options.selected = options.get_item_id(i)
			emit_signal("plugin_changed", cur_plugin)
			checkbox.pressed = enabled
			break

func show_warning(_p_name : String) -> void:
	var _text = "Plugin '%s' is disabled.\n Do you want to enable it?" % _p_name
	$ConfirmationDialog.dialog_text = _text
	$ConfirmationDialog.popup_centered()

func _on_OptionsItem_selected(_ind : int) -> void:
	cur_plugin = options.get_item_metadata(options.selected)
	emit_signal("plugin_changed", cur_plugin)
	checkbox.pressed = enabled

func _on_CheckBox_toggled(_pressed : bool) -> void:
	if options.get_item_count() == 0:
		checkbox.pressed = false
		return
	emit_signal("request_%s_plugin" % ("enable" if _pressed else "disable"), cur_plugin)

func _on_RefreshButton_pressed() -> void:
	if options.get_item_count() == 0:
		return
	emit_signal("request_refresh_plugin", cur_plugin)

func _on_ConfirmationDialog_confirmed() -> void:
	emit_signal("request_enable_plugin", cur_plugin)
	checkbox.pressed = enabled
