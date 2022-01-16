tool
extends EditorPlugin

var plugin_config = ConfigFile.new() as ConfigFile
var refresher_scene = load("res://addons/godot-plugin-refresher/plugin_refresher.tscn") as PackedScene
var refresher : HBoxContainer

func _enter_tree() -> void:
	refresher = refresher_scene.instance()
	var _theme = get_editor_interface().get_base_control()
	refresher.refresh_icon = _theme.get_icon("Reload", "EditorIcons")
	add_control_to_container(CONTAINER_TOOLBAR, refresher)
	var _editor_fs: EditorFileSystem = get_editor_interface().get_resource_filesystem()
	assert(OK == _editor_fs.connect("filesystem_changed", self, "_on_filesystem_changed"))
	assert(OK == refresher.connect("request_refresh_plugin", self, "_on_refresh_plugin_request"))
	assert(OK == refresher.connect("request_enable_plugin", self, "_on_enable_request", [true]))
	assert(OK == refresher.connect("request_disable_plugin", self, "_on_enable_request", [false]))
	assert(OK == refresher.connect("plugin_changed", self, "_on_plugin_changed"))
	reload_plugins_list()
	load_settings()

func reload_plugins_list() -> void:
	var _dir := Directory.new()
	assert(OK == _dir.open("res://addons/"))
	assert(OK == _dir.list_dir_begin(true, true))
	var _file := _dir.get_next()
	var _plugins := {}
	var _origins := {}
	while _file:
		var _addon_dir := "res://addons/%s" % _file
		var _is_cur_plugin := (_file == get_plugin_path().get_file())
		if _dir.dir_exists(_addon_dir) and !_is_cur_plugin:
			var _config_path = "%s/plugin.cfg" % _addon_dir
			if !_dir.file_exists(_config_path):
				_file = _dir.get_next()
				continue
			var _plugin_cfg := ConfigFile.new()
			assert(OK == _plugin_cfg.load(_config_path))
			var _p_name: String = _plugin_cfg.get_value("plugin", "name", _file)
			if !_p_name in _origins:
				_origins[_p_name] = [_file]
			else:
				_origins[_p_name].append(_file)
				_p_name = "%s (%s)" % [_p_name, _file]
			_plugins[_file] = _p_name
		_file = _dir.get_next()
	refresher.update_items(_plugins)

func get_plugin_path() -> String:
	return get_script().resource_path.get_base_dir()

func load_settings()-> void:
	var _cfg_path := get_config_path()
	var _dir := Directory.new()
	if !_dir.file_exists(_cfg_path):
		var config := ConfigFile.new()
		assert(OK == _dir.make_dir_recursive(_cfg_path.get_base_dir()))
		assert(OK == config.save(_cfg_path))
	else:
		plugin_config.load(_cfg_path)

func get_config_path() -> String:
	var _dir := get_editor_interface().get_editor_settings().get_project_settings_dir()
	var _path := "%s/plugins/plugin_refresher/settings.cfg" % _dir
	return _path

func _exit_tree() -> void:
	remove_control_from_container(CONTAINER_TOOLBAR, refresher)

func save_settings() -> void:
	plugin_config.save(get_config_path())

func _on_filesystem_changed() -> void:
	if refresher:
		reload_plugins_list()
		refresher.select_plugin(get_recent_plugin())

func get_recent_plugin() -> String:
	return plugin_config.get_value("settings", "recently_used", "")

func is_enabled(_p_name: String) -> bool:
	return get_editor_interface().is_plugin_enabled(_p_name)

func _on_enable_request(_p_name: String, _enable: bool) -> void:
	assert(!_p_name.empty())
	if is_enabled(_p_name) == _enable:
		return
	get_editor_interface().set_plugin_enabled(_p_name, _enable)
	refresher.enabled = is_enabled(_p_name)
	plugin_config.set_value("settings", "recently_used", _p_name)
	save_settings()

func _on_refresh_plugin_request(_p_name: String) -> void:
	assert(!_p_name.empty())
	if !is_enabled(_p_name):
		refresher.show_warning(_p_name)
	else:
		refresher.emit_signal("request_disable_plugin", _p_name)
		yield(get_tree(), "idle_frame")
		refresher.emit_signal("request_enable_plugin", _p_name)

func _on_confirm_refresh_plugin(_p_name: String)-> void:
	refresher.emit_signal("request_enable_plugin", [_p_name])

func _on_plugin_changed(_p_name: String) -> void:
	if !refresher:
		return
	refresher.enabled = is_enabled(_p_name)
	plugin_config.set_value("settings", "recently_used", _p_name)
	save_settings()
