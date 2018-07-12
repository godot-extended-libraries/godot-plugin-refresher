tool
extends EditorPlugin

const Wrapper = preload("wrapper.gd")

var refresher
var front_hbox

func _enter_tree():
	refresher = Wrapper.new()
	add_control_to_container(CONTAINER_TOOLBAR, refresher)
	#front_hbox = refresher.get_parent().get_child(1)
	
	#refresher.set_owner(front_hbox.get_owner())
	
	#front_hbox.add_child(refresher)
	
	var efs = get_editor_interface().get_resource_filesystem()
	efs.connect("filesystem_changed", self, "_on_filesystem_changed")
	
	refresher.connect("request_refresh_plugin", self, "_on_request_refresh_plugin")

func _exit_tree():
	remove_control_from_container(CONTAINER_TOOLBAR, refresher)
	#front_hbox.remove_child(refresher)
	refresher.free()

func _on_filesystem_changed():
	refresher.reload_items()

func _on_request_refresh_plugin(p_name):
	get_editor_interface().set_plugin_enabled(p_name, false)
	get_editor_interface().set_plugin_enabled(p_name, true)