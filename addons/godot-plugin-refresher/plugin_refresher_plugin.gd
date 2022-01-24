tool
extends EditorPlugin

const Refresher = "./plugin_refresher.tscn"

var cfg := ConfigFile.new()
var refresher: HBoxContainer


func _enter_tree() -> void:
	refresher = preload(Refresher).instance()
	add_control_to_container(0, refresher)
	var filesystem := get_editor_interface().get_resource_filesystem()
	assert(OK == filesystem.connect("filesystem_changed", self, "_on_filesystem_changed"))
	assert(OK == refresher.connect("request_refresh_plugin", self, "_on_refresh_plugin_request"))
	assert(OK == refresher.connect("request_enable_plugin", self, "_on_enable_request", [true]))
	assert(OK == refresher.connect("request_disable_plugin", self, "_on_enable_request", [false]))
	assert(OK == refresher.connect("plugin_changed", self, "_on_plugin_changed"))
	_reload_plugins_list()
	_load_settings()


func _exit_tree() -> void:
	remove_control_from_container(CONTAINER_TOOLBAR, refresher)
	refresher.queue_free()


func _reload_plugins_list() -> void:
	var dir := Directory.new()
	assert(OK == dir.open("res://addons/"))
	assert(OK == dir.list_dir_begin(true, true))
	var display_name := dir.get_next()
	var plugins := {}
	var origins := {}
	while display_name:
		var addon_dir := "res://addons/%s" % display_name
		var is_cur_plugin := (display_name == _get_plugin_path().get_file())
		if dir.dir_exists(addon_dir) and not is_cur_plugin:
			var config_path = "%s/plugin.cfg" % addon_dir
			if not dir.file_exists(config_path):
				display_name = dir.get_next()
				continue
			var plugin_cfg := ConfigFile.new()
			assert(OK == plugin_cfg.load(config_path))
			var plugin_name: String = plugin_cfg.get_value("plugin", "name", display_name)
			if not plugin_name in origins:
				origins[plugin_name] = [display_name]
			else:
				origins[plugin_name].append(display_name)
				plugin_name = "%s (%s)" % [plugin_name, display_name]
			plugins[display_name] = plugin_name
		display_name = dir.get_next()
	refresher.update_items(plugins)


func _get_plugin_path() -> String:
	return get_script().resource_path.get_base_dir()


func _load_settings()-> void:
	var cfg_path := _get_config_path()
	var dir := Directory.new()
	if not dir.file_exists(cfg_path):
		var config := ConfigFile.new()
		assert(OK == dir.make_dir_recursive(cfg_path.get_base_dir()))
		assert(OK == config.save(cfg_path))
	else:
		cfg.load(cfg_path)


func _get_config_path() -> String:
	var dir := get_editor_interface().get_editor_settings().get_project_settings_dir()
	return "%s/plugins/plugin_refresher/settings.cfg" % dir


func _save_settings() -> void:
	assert(OK == cfg.save(_get_config_path()))


func _on_filesystem_changed() -> void:
	if not refresher:
		return
	_reload_plugins_list()
	refresher.select_plugin(_get_recent_plugin())


func _get_recent_plugin() -> String:
	return cfg.get_value("settings", "recently_used", "")


func is_enabled(plugin_name: String) -> bool:
	return get_editor_interface().is_plugin_enabled(plugin_name)


func _on_enable_request(plugin_name: String, enable: bool) -> void:
	if not plugin_name or is_enabled(plugin_name) == enable:
		return
	get_editor_interface().set_plugin_enabled(plugin_name, enable)
	refresher.enabled = is_enabled(plugin_name)
	cfg.set_value("settings", "recently_used", plugin_name)
	_save_settings()


func _on_refresh_plugin_request(plugin_name: String) -> void:
	if not plugin_name:
		return
	if not is_enabled(plugin_name):
		refresher.show_warning(plugin_name)
	else:
		refresher.emit_signal("request_disable_plugin", plugin_name)
		refresher.call_deferred("emit_signal", "request_enable_plugin", plugin_name)


func _on_confirm_refresh_plugin(plugin_name: String) -> void:
	refresher.emit_signal("request_enable_plugin", plugin_name)


func _on_plugin_changed(plugin_name: String) -> void:
	if not refresher:
		return
	refresher.enabled = is_enabled(plugin_name)
	cfg.set_value("settings", "recently_used", plugin_name)
	_save_settings()
