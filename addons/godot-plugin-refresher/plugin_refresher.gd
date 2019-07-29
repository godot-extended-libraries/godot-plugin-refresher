tool
extends HBoxContainer

const ADDONS_PATH = "res://addons/"
const PLUGIN_PATH = "godot-plugin-refresher"

signal request_refresh_plugin(p_name)

onready var options = $OptionButton

func _ready():
	reload_items()

func reload_items():
	if not options:
		return
	var dir = Directory.new()
	dir.change_dir(ADDONS_PATH)
	dir.list_dir_begin(true, true)
	var file = dir.get_next()
	options.clear()
	while file:
		if dir.dir_exists(ADDONS_PATH.plus_file(file)) and file != PLUGIN_PATH:
			options.add_item(file)
		file = dir.get_next()

func select_plugin(p_name):
	if not options:
		return
	if p_name == null or p_name.empty():
		return

	for idx in options.get_item_count():
		var plugin = options.get_item_text(idx)
		if plugin == p_name:
			options.selected = options.get_item_id(idx)

func set_refresh_button_icon(p_icon):
	$RefreshButton.icon = p_icon

func _on_RefreshButton_pressed():
	if options.selected == -1:
		return # nothing selected

	var plugin = options.get_item_text(options.selected)
	if not plugin or plugin.empty():
		return
	emit_signal("request_refresh_plugin", plugin)
