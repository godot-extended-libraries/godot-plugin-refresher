@tool
extends HBoxContainer

signal request_refresh_plugin(p_name: String)
signal confirm_refresh_plugin(p_name: String)

@onready var options: OptionButton = $OptionButton


func _ready() -> void:
	if get_tree().edited_scene_root == self:
		return  # This is the scene opened in the editor!
	$RefreshButton.icon = EditorInterface.get_editor_theme().get_icon("Reload", "EditorIcons")


func update_items(p_plugins: Dictionary) -> void:
	if not options:
		return
	options.clear()
	var plugin_dirs: Array[String] = []
	plugin_dirs.assign(p_plugins.keys())
	for idx in plugin_dirs.size():
		var plugin_dirname := plugin_dirs[idx] as String
		var plugin_name := p_plugins[plugin_dirname] as String
		options.add_item(plugin_name, idx)
		options.set_item_metadata(idx, plugin_dirname)


# Note: For whatever reason, statically typing `p_name` inexplicably causes
# an error about converting from Nil to String, even if the value is converted.
func select_plugin(p_name) -> void:
	if not options or not p_name:
		return

	for idx in options.get_item_count():
		var plugin := str(options.get_item_metadata(idx))
		if plugin == str(p_name):
			options.selected = options.get_item_id(idx)
			break


func _on_RefreshButton_pressed() -> void:
	if options.selected == -1:
		return  # nothing selected

	var plugin := str(options.get_item_metadata(options.selected))
	if not plugin:
		return
	emit_signal("request_refresh_plugin", plugin)


func show_warning(p_name: String) -> void:
	$ConfirmationDialog.dialog_text = (
		"""
		Plugin `%s` is currently disabled.\n
		Do you want to enable it now?
	"""
		% [p_name]
	)
	$ConfirmationDialog.popup_centered()


func _on_ConfirmationDialog_confirmed() -> void:
	var plugin := options.get_item_metadata(options.selected) as String
	emit_signal("confirm_refresh_plugin", plugin)
