tool
extends EditorPlugin


const ADDONS_PATH = "res://addons/"
const PLUGIN_CONFIG_DIR = "plugins/plugin_refresher"
const PLUGIN_CONFIG = "settings.cfg"
const SETTINGS = "settings"
const SETTING_RECENT = "recently_used"

var plugin_config := ConfigFile.new()
var plugin_paths := {}
var refresher


func _enter_tree():
	refresher = preload("plugin_refresher.tscn").instance()
	add_control_to_container(CONTAINER_TOOLBAR, refresher)

	# Watch whether any plugin is changed, added or removed on the filesystem
	var efs = get_editor_interface().get_resource_filesystem()
	efs.connect("filesystem_changed", self, "_on_filesystem_changed")

	refresher.connect("request_refresh_plugin", self, "_on_request_refresh_plugin")
	refresher.connect("confirm_refresh_plugin", self, "_on_confirm_refresh_plugin")

	_reload_plugins_list()
	_load_settings()


func _exit_tree():
	remove_control_from_container(CONTAINER_TOOLBAR, refresher)
	refresher.free()


func _reload_plugins_list():
	var refresher_dir : String = get_plugin_path().get_file()
	var cfg_paths := []
	var plugins := {}

	find_cfgs(ADDONS_PATH, cfg_paths)
	plugin_paths.clear()
	
	for cfg_path in cfg_paths:
		var plugin_cfg = ConfigFile.new()
		var ERR = plugin_cfg.load(cfg_path)
		if ERR == OK:
			var p_name = plugin_cfg.get_value("plugin", "name")
			if p_name != "Godot Plugin Refresher":
				var p_path = cfg_path.split("addons/")[-1].split("/plugin.cfg")[0]
				plugin_paths[p_name] = p_path
				plugins[p_path] = p_name
		else:
			push_error("ERROR LOADING PLUGIN FILE: %s" % ERR)
	
	
	refresher.update_items(plugins)


func find_cfgs(dir_path:String, cfgs:Array):
	var dir := Directory.new()
	
	var cfg_path = dir_path.plus_file("plugin.cfg")
	if dir.file_exists(cfg_path):
		cfgs.append(cfg_path)
		return
	
	if dir.open(dir_path) == OK:
		dir.list_dir_begin(true)
		
		var file_name = dir.get_next()
		while file_name != "":
			
			if dir.current_is_dir():
				find_cfgs(dir_path.plus_file(file_name), cfgs)
			
			file_name = dir.get_next()


func _load_settings():
	var path = get_config_path()

	var fs = Directory.new()
	if not fs.file_exists(path):
		# Create new if running for the first time
		var config = ConfigFile.new()
		fs.make_dir_recursive(path.get_base_dir())
		config.save(path)
	else:
		plugin_config.load(path)


func _save_settings():
	plugin_config.save(get_config_path())


func get_config_path():
	var dir = get_editor_interface().get_editor_settings().get_project_settings_dir()
	var home = dir.plus_file(PLUGIN_CONFIG_DIR)
	var path = home.plus_file(PLUGIN_CONFIG)

	return path


func _on_filesystem_changed():
	if refresher:
		_reload_plugins_list()
		refresher.select_plugin(get_recent_plugin())


func get_recent_plugin():
	if not plugin_config.has_section_key(SETTINGS, SETTING_RECENT):
		return null # not saved yet

	var recent = plugin_config.get_value(SETTINGS, SETTING_RECENT)
	return recent


func _on_request_refresh_plugin(p_name):
	assert(not p_name.empty())

	var disabled = not get_editor_interface().is_plugin_enabled(p_name)
	if disabled:
		refresher.show_warning(p_name)
	else:
		refresh_plugin(p_name)


func _on_confirm_refresh_plugin(p_name):
	refresh_plugin(p_name)


func get_plugin_path():
	return get_script().resource_path.get_base_dir()


func refresh_plugin(p_name):
	print("Refreshing plugin: ", p_name)

	var enabled = get_editor_interface().is_plugin_enabled(p_name)
	if enabled: # can only disable an active plugin
		get_editor_interface().set_plugin_enabled(p_name, false)

	get_editor_interface().set_plugin_enabled(p_name, true)

	plugin_config.set_value(SETTINGS, SETTING_RECENT, p_name)
	_save_settings()
