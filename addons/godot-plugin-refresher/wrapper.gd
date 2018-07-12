extends HBoxContainer

signal request_refresh_plugin(p_name)

var node

func _init():
	node = preload("plugin_refresher.tscn").instance()
	node.connect("request_refresh_plugin", self, "_on_request_refresh_plugin")
	add_child(node)

func _on_request_refresh_plugin(p_name):
	emit_signal("request_refresh_plugin", p_name)

func reload_items():
	node.reload_items()