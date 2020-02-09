tool
extends HBoxContainer

signal request_refresh_plugin(p_name)
signal confirm_refresh_plugin(p_name)

onready var options = $OptionButton

func _ready():
	$RefreshButton.icon = get_icon('Reload', 'EditorIcons')

func update_items(p_plugins):
	if not options:
		return
	options.clear()
	for plugin_name in p_plugins:
		options.add_item(plugin_name)

func select_plugin(p_name):
	if not options:
		return
	if p_name == null or p_name.empty():
		return

	for idx in options.get_item_count():
		var plugin = options.get_item_text(idx)
		if plugin == p_name:
			options.selected = options.get_item_id(idx)
			break

func _on_RefreshButton_pressed():
	if options.selected == -1:
		return # nothing selected

	var plugin = options.get_item_text(options.selected)
	if not plugin or plugin.empty():
		return
	emit_signal("request_refresh_plugin", plugin)

func show_warning(p_name):
	$ConfirmationDialog.dialog_text = """
		Plugin `%s` is currently disabled.\n
		Do you want to enable it now?
	""" % [p_name]
	$ConfirmationDialog.popup_centered()

func _on_ConfirmationDialog_confirmed():
	var plugin = options.get_item_text(options.selected)
	emit_signal('confirm_refresh_plugin', plugin)
