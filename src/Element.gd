extends Control
class_name Element

var module: Module = null
var timer: Timer = null

func init(module: Module = null):
	assert(module.config != null)
	self.module = module
	module.registerElement(self)
	updateInfo()
	
	if "poll-interval" in module.config:
		setPollInterval(module.config["poll-interval"])

func setPollInterval(value: float):
	assert(module)
	
	if value <= 0:
		if timer:
			timer.queue_free()
			timer = null
		return
	
	if not timer:
		timer = Timer.new()
		add_child(timer)
		timer.connect("timeout", module, "updateElement", [self])
	
	timer.wait_time = value
	
	if is_inside_tree():
		timer.start()
	else:
		timer.autostart = true

func updateInfo():
	assert(module)
	module.updateElement(self)

func connectGuiInput(object: Object, method: String, binds: Array = []):
	connect("gui_input", object, method, binds)

class Module:
	var config: Dictionary = null
	static func getType() -> String:
		assert(false)
		return ""
	static func create(_config: Dictionary) -> Element:
		assert(false)
		return null
	func registerElement(_element: Element) -> void:
		pass
	func updateElement(_element: Element) -> void:
		pass

#class GDScriptModule extends Module:
#	var function: FuncRef
#	func _init(function: FuncRef):
#		self.function = function
#
#	func getText() -> String:
#		return function.call_func()
#
#class CommandModule extends Module:
#
#	var path: String
#	var arguments: PoolStringArray
#
#	func _init(path: String, arguments: PoolStringArray):
#		self.path = path
#		self.arguments = arguments
#
#	func getText() -> String:
#		var result: Array = []
#		OS.execute(path, arguments, true, result, true)
#
#		if result.empty():
#			return ""
#
#		return result[0].strip_escapes()
