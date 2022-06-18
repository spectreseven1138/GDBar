extends Control
class_name GDBar

enum ALIGNMENT {
	LEFT, CENTER, RIGHT
}

onready var CONTAINERS: Dictionary = {
	ALIGNMENT.LEFT: $MarginContainer/Elements/LeftContainer,
	ALIGNMENT.CENTER: $MarginContainer/Elements/CenterContainer,
	ALIGNMENT.RIGHT: $MarginContainer/Elements/RightContainer
}

const MODULE_TYPES: Dictionary = {}

static func getColour(colour: String):
	
	if "pallette" in Config.config and colour in Config.config["pallette"]:
		return Color(Config.config["pallette"][colour])
	
	return Color(colour)

static func getStyle(style, default: Dictionary) -> Dictionary:
	var ret: Dictionary
	
	if style is Dictionary:
		ret = style
	elif "styles" in Config.config and style in Config.config["styles"]:
		ret = Config.config["styles"][style]
	else:
		return default
	
	for key in default:
		if not key in ret:
			ret[key] = default[key]
	
	return ret

func _init():
	for module_type in [BasicModules.MediaAPIModule, BasicModules.VolumeModule, BasicModules.TimeModule]:
		MODULE_TYPES[module_type.getType()] = module_type

func addElement(element: Element, alignment: int):
	assert(alignment in CONTAINERS)
	CONTAINERS[alignment].add_child(element)

func loadConfig(path: String):
	
	var f: File = File.new()
	var err: int = f.open(path, File.READ)
	assert(err == OK)
	
	var config: Dictionary = parse_json(f.get_as_text())
	f.close()
	
	Config.config = config
	
	if "bg-colour" in config:
		$BG.color = getColour(config["bg-colour"])
	
	var module_configs: Dictionary = config["modules"] if "modules" in config else {}
	
	for layout in [["layout-left", ALIGNMENT.LEFT], ["layout-center", ALIGNMENT.CENTER], ["layout-right", ALIGNMENT.RIGHT]]:
		if not layout[0] in config:
			continue
		
		for item in config[layout[0]]:
			var item_config: Dictionary
			var type: GDScript
			
			if item in module_configs:
				item_config = module_configs[item]
				type = MODULE_TYPES[item_config["type"]]
			else:
				item_config = {}
				type = MODULE_TYPES[item]
			
			var element: Element = type.create(item_config)
			addElement(element, layout[1])
	
#	var volume_element: SliderElement = preload("res://src/elements/SliderElement.tscn").instance()
#	volume_element.init(BasicModules.VolumeModule.new())
#	addElement(volume_element, ALIGNMENT.RIGHT)
#
#	var media_element: BasicElement = preload("res://src/elements/BasicElement.tscn").instance()
#	media_element.init(BasicModules.MediaAPIModule.new())
#	addElement(media_element, ALIGNMENT.RIGHT)
#
#	var time_element: BasicElement = preload("res://src/elements/BasicElement.tscn").instance()
#	time_element.init(BasicModules.TimeModule.new())
#	addElement(time_element, ALIGNMENT.RIGHT)
