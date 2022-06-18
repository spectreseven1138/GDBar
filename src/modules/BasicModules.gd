extends Node

class TimeModule extends Element.Module:
	const WEEKDAY_NAMES: Array = [
		"Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"
	]
	
	static func getType():
		return "time"
	
	static func create(config: Dictionary):
		var element: Element = preload("res://src/elements/BasicElement.tscn").instance()
		var module: Element.Module = TimeModule.new()
		module.config = config
		element.init(module)
		return element
	
	func registerElement(element: Element):
		element.connectGuiInput(self, "onGuiEvent", [element])
	
	func onGuiEvent(event: InputEvent, element: Element):
		if event is InputEventMouseButton and event.button_index == BUTTON_LEFT and event.pressed:
			element.setData("")
			yield(element.get_tree().create_timer(2), "timeout")
			element.setData("Hello World")
	
	func updateElement(element: Element):
		var time: Dictionary = OS.get_datetime()
		for key in time:
			if key == "dst":
				continue
			if key == "weekday":
				time[key] = WEEKDAY_NAMES[time[key]]
				continue
			
			if time[key] < 10:
				var text: String = str(time[key])
				time[key] = "0".repeat(2 - min(len(text), 2)) + text
			else:
				time[key] = str(time[key])
		
		# TODO | Config
		# year, month, day, weekday, hour, minute, second
		element.setData(time["weekday"] + " " + time["month"] + "/" + time["day"] + " " + time["hour"] + ":" + time["minute"])

class VolumeModule extends Element.Module:
	
	static func getType():
		return "volume"
	
	static func create(config: Dictionary):
		
		var scene: PackedScene
		if "slider" in config and config["slider"]:
			scene = preload("res://src/elements/SliderElement.tscn")
		else:
			scene = preload("res://src/elements/BasicElement.tscn")
		
		var element: Element = scene.instance()
		var module: Element.Module = VolumeModule.new()
		module.config = config
		element.init(module)
		return element
	
	static func getVolume() -> float:
		var result: Array = []
		OS.execute("amixer", ["get", "Master"], true, result, true)
		
		var data: String = result[0]
		
		var volume: String = null
		for line in data.split("\n"):
			line = line.strip_edges(true, false)
			if not line.begins_with("Front Left: "):
				continue
			
			for i in len(line) - 12:
				i += 12
				
				var c: String = line[i]
				if volume == null:
					if c == "[":
						volume = ""
				else:
					if c == "%":
						break
					else:
						volume += c
		
		return float(volume) / 100.0
	
	static func setVolume(value: float):
		OS.execute("amixer", ["-q", "sset", "Master", str(int(value * 100.0)) + "%"])
	
	func registerElement(element: Element):
		element.resize_mode = BasicElement.RESIZE_MODE.FIXED
		element.rect_min_size.x = 100
		if element is SliderElement:
			element.connect("VALUE_CHANGED", self, "onSliderValueChanged", [element])
		else:
			element.connectGuiInput(self, "onElementGuiInput", [element])
	
	func onElementGuiInput(event: InputEvent, element: Element):
		if event is InputEventMouseButton:
			var polarity: int = 0
			if event.button_index == BUTTON_WHEEL_UP:
				polarity = 1
			elif event.button_index == BUTTON_WHEEL_DOWN:
				polarity = -1
			
			if polarity != 0:
				var volume: float
				if element.has_meta("volume_cache"):
					volume = element.get_meta("volume_cache")
				else:
					volume = getVolume()
				
				volume += polarity * SliderElement.SCROLL_STEP
				setVolume(volume)
				
				updateElement(element, volume)
	
	func onSliderValueChanged(slider: SliderElement):
		var percentage: String = str(int(slider.value * 100))
		OS.execute("amixer", ["-q", "sset", "Master", percentage + "%"])
		updateElement(slider, slider.value)
	
	func updateElement(element: Element, volume: float = getVolume()):
		element.setData(str(int(volume * 100.0)) + "%")
		if element is SliderElement:
			element.value = volume
		else:
			element.set_meta("volume_cache", volume)

class MediaAPIModule extends Element.Module:
	
	const DEFAULT_LAYOUT: Array = ["info", "previous", "playpause", "next"]
	
	const DEFAULT_LABEL_STYLE: Dictionary = {
		"font": "res://fonts/NotoSansCJKjp-Regular.ttf",
		"font_colour": "000000",
		"font_size": 13
	}
	
	const DEFAULT_PLAYPAUSE_STYLE: Dictionary = {
		"play_icon": "res://icons/play.png",
		"pause_icon": "res://icons/pause.png"
	}
	
	const DEFAULT_NEXT_STYLE: Dictionary = {
		"icon": "res://icons/next.png"
	}
	
	const DEFAULT_PREVIOUS_STYLE: Dictionary = {
		"icon": "res://icons/previous.png"
	}
	
#		"stop": "res://icons/stop.png",

	static func getType():
		return "media-api"
	
	static func create(config: Dictionary):
		var element: BasicElement = preload("res://src/elements/BasicElement.tscn").instance()
		var module: Element.Module = MediaAPIModule.new();
		module.config = config
		
		if "layout" in config:
			var layout: Dictionary = config["layout"]
			var layout_indices: Dictionary = {}
			
			var i: int = 0
			for sub_element in layout:
				
				layout_indices[sub_element] = i
				i += 1
				
				var node: Node
				match sub_element:
					"info":
						node = Label.new()
						node.visible = false
						
						var style: Dictionary = DEFAULT_LABEL_STYLE
						if "style" in layout[sub_element]:
							style = GDBar.getStyle(layout[sub_element]["style"], DEFAULT_LABEL_STYLE)
						
						var font: DynamicFont = DynamicFont.new()
						font.font_data = load(style["font"])
						font.size = style["font_size"]
						
						node.set("custom_fonts/font", font)
						node.set("custom_colors/font_color", GDBar.getColour(style["font_colour"]))
						
					"playpause":
						node = TextureButton.new()
						node.visible = true
						node.expand = true
						node.stretch_mode = TextureButton.STRETCH_KEEP_ASPECT_CENTERED
						node.rect_min_size = Vector2(12, 12)
						node.modulate.a = 0.7
						
						var style: Dictionary = DEFAULT_PLAYPAUSE_STYLE
						if "style" in layout[sub_element]:
							style = GDBar.getStyle(layout[sub_element]["style"], DEFAULT_PLAYPAUSE_STYLE)
						
						node.texture_normal = load(style["play_icon"])
						node.texture_pressed = load(style["pause_icon"])
						
					"next":
						node = TextureButton.new()
						node.visible = true
						node.expand = true
						node.stretch_mode = TextureButton.STRETCH_KEEP_ASPECT_CENTERED
						node.rect_min_size = Vector2(12, 12)
						
						var style: Dictionary = DEFAULT_NEXT_STYLE
						if "style" in layout[sub_element]:
							style = GDBar.getStyle(layout[sub_element]["style"], DEFAULT_NEXT_STYLE)
						
						node.texture_normal = load(style["icon"])
						node.texture_pressed = node.texture_normal
						
					"previous":
						node = TextureButton.new()
						node.visible = true
						node.expand = true
						node.stretch_mode = TextureButton.STRETCH_KEEP_ASPECT_CENTERED
						node.rect_min_size = Vector2(12, 12)
						
						var style: Dictionary = DEFAULT_PREVIOUS_STYLE
						if "style" in layout[sub_element]:
							style = GDBar.getStyle(layout[sub_element]["style"], DEFAULT_PREVIOUS_STYLE)
						
						node.texture_normal = load(style["icon"])
						node.texture_pressed = node.texture_normal
					_:
						assert(false, "Unknown subelement '" + sub_element + "'")
						continue
				
				element.addSubElement(node)
			element.set_meta("layout", layout_indices)
		else:
			element.set_meta("layout", {})
		
		element.init(module)
		return element
	
	static func getMediaInfo() -> Dictionary:
		var result: Array = []
		OS.execute("mediaAPI", ["client", "getinfo"], true, result, true)
		return parse_json(result[0])
	
	func updateElement(element: Element):
		
		var info: Dictionary = getMediaInfo()
		
		var layout: Dictionary = element.get_meta("layout")
		if "info" in layout:
			if not info["visible"]:
				element.setData("", layout["info"])
			else:
				element.setData(info["title"], layout["info"])
		
